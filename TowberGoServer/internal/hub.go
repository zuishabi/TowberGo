package internal

import (
	"TowberGoServer/internal/containers"
	"TowberGoServer/internal/db"
	"TowberGoServer/pkg/packets"
	"gorm.io/gorm"
	"log"
	"net/http"
	"sync/atomic"
)

// ClientStateHandler 用于处理客户端消息的状态机结构
type ClientStateHandler interface {
	Name() string
	// SetClient 将客户端注入到状态中
	SetClient(client ClientInterface)
	// OnEnter 每次状态改变时调用
	OnEnter()
	HandleMessage(senderID uint32, message packets.Msg)
	OnExit()
	// ClearResources 回收资源
	ClearResources()
}

type ClientInterface interface {
	// Initialize 初始化客户端
	Initialize(id uint32)
	// ID 返回客户端id
	ID() uint32
	// ProcessMessage 处理消息
	ProcessMessage(senderID uint32, message packets.Msg)
	SetState(newState ClientStateHandler)
	// SocketSend 将数据写入write pump中
	SocketSend(message packets.Msg)
	// SocketSendAs 从其他客户端那里转发数据到write pump
	SocketSendAs(message packets.Msg, senderID uint32)
	// PassToPeer 将数据发送给特定客户端
	PassToPeer(message packets.Msg, peerID uint32)
	// WritePump 将数据写到客户端
	WritePump()
	// ReadPump 从客户端socket连接中读取数据
	ReadPump()
	Db() *gorm.DB
	// Close 关闭连接并清除资源
	Close(reason string)
	Login(newID uint32)
	Hub() *Hub
	Lock()
	UnLock()
}

type Hub struct {
	Db *gorm.DB
	// 已经登录的客户端
	LoginClients *containers.SharedIDMap[ClientInterface]
	// 未登录的客户端
	ConnectedClients *containers.SharedIDMap[ClientInterface]
	connectedID      atomic.Uint32
	broadcastChan    chan *packets.Packet
}

func NewHub() *Hub {
	database, err := db.NewDb()
	if err != nil {
		log.Fatal(err)
	}
	if err := db.UpdateStructs(database); err != nil {
		log.Fatal(err)
	}
	return &Hub{
		Db:               database,
		LoginClients:     containers.NewSharedIDMap[ClientInterface](),
		ConnectedClients: containers.NewSharedIDMap[ClientInterface](),
		broadcastChan:    make(chan *packets.Packet),
	}
}

func (h *Hub) BroadCast(packet *packets.Packet) {
	h.broadcastChan <- packet
}

func (h *Hub) Run() {
	for {
		select {
		case packet := <-h.broadcastChan:
			h.LoginClients.ForEach(func(id uint32, client ClientInterface) {
				client.Lock()
				if client != nil && id != packet.Uid {
					client.ProcessMessage(packet.Uid, packet.Msg)
				}
				client.UnLock()
			})
		}
	}
}

func (h *Hub) Serve(getNewClient func(*Hub, http.ResponseWriter, *http.Request) (ClientInterface, error), writer http.ResponseWriter, request *http.Request) {
	log.Println("new client connecting:", request.RemoteAddr)
	client, err := getNewClient(h, writer, request)
	if err != nil {
		log.Println("create client failed", err)
		return
	}

	id := h.connectedID.Add(1)
	h.ConnectedClients.Set(id, client)
	client.Initialize(id)
	go client.WritePump()
	go client.ReadPump()
}
