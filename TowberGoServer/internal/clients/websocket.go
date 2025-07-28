package clients

import (
	"TowberGoServer/internal"
	"TowberGoServer/internal/states"
	"TowberGoServer/pkg/packets"
	"fmt"
	"github.com/gorilla/websocket"
	"google.golang.org/protobuf/proto"
	"gorm.io/gorm"
	"log"
	"net/http"
	"sync/atomic"
)

type WebSocketClient struct {
	id       uint32
	conn     *websocket.Conn
	hub      *internal.Hub
	state    internal.ClientStateHandler
	logger   *log.Logger
	sendChan chan *packets.Packet
	closed   atomic.Bool
}

func NewWebSocketClient(hub *internal.Hub, writer http.ResponseWriter, request *http.Request) (internal.ClientInterface, error) {
	upgrader := websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
		CheckOrigin:     func(_ *http.Request) bool { return true },
	}
	conn, err := upgrader.Upgrade(writer, request, nil)
	if err != nil {
		return nil, err
	}
	c := &WebSocketClient{
		conn:     conn,
		hub:      hub,
		logger:   log.New(log.Writer(), "Client unknown: ", log.LstdFlags),
		sendChan: make(chan *packets.Packet, 256),
	}
	return c, nil
}

func (c *WebSocketClient) Initialize(id uint32) {
	c.id = id
	c.logger.SetPrefix(fmt.Sprintf("Client %d:", c.id))
	c.SetState(&states.Connected{})
}

func (c *WebSocketClient) ID() uint32 {
	return c.id
}

func (c *WebSocketClient) ProcessMessage(senderID uint32, message packets.Msg) {
	c.state.HandleMessage(senderID, message)
}

func (c *WebSocketClient) SetState(newState internal.ClientStateHandler) {
	prevStateName := "None"
	if c.state != nil {
		prevStateName = c.state.Name()
		c.state.OnExit()
	}
	newStateName := "None"
	if newState != nil {
		newStateName = newState.Name()
	}
	c.logger.Printf("Switching from state %s to %s", prevStateName, newStateName)
	c.state = newState
	if c.state != nil {
		c.state.SetClient(c)
		c.state.OnEnter()
	}
}

func (c *WebSocketClient) SocketSend(message packets.Msg) {
	c.SocketSendAs(message, 0)
}

func (c *WebSocketClient) SocketSendAs(message packets.Msg, senderId uint32) {
	select {
	case c.sendChan <- &packets.Packet{
		Uid: senderId,
		Msg: message,
	}:
	default:
		c.logger.Printf("Send channel full,dropping message: %T", message)
	}
}

func (c *WebSocketClient) PassToPeer(message packets.Msg, peerId uint32) {
	if peer, exists := c.hub.LoginClients.Get(peerId); exists {
		peer.ProcessMessage(c.id, message)
	}
}

func (c *WebSocketClient) WritePump() {
	defer func() {
		c.logger.Println("Closing write pump")
		c.Close("write pump closed")
	}()
	for packet := range c.sendChan {
		writer, err := c.conn.NextWriter(websocket.BinaryMessage)
		if err != nil {
			c.logger.Printf("error getting writer from %T packet,closing client: %v", packet.Msg, err)
			return
		}
		data, err := proto.Marshal(packet)
		if err != nil {
			c.logger.Printf("error marshalling %T packet,closing client: %v", packet.Msg, err)
			continue
		}
		_, err = writer.Write(data)
		if err != nil {
			c.logger.Printf("error writing %T packet: %v", packet.Msg, err)
			continue
		}
		_, _ = writer.Write([]byte{'\n'})
		if err = writer.Close(); err != nil {
			c.logger.Printf("error closing writer for %T packet: %v", packet.Msg, err)
			continue
		}
	}
}

func (c *WebSocketClient) ReadPump() {
	defer func() {
		c.logger.Println("Closing read pump")
		c.Close("read pump closed")
	}()
	for {
		_, data, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				c.logger.Printf("Error: %v", err)
			}
			break
		}
		packet := &packets.Packet{}
		err = proto.Unmarshal(data, packet)
		if err != nil {
			c.logger.Printf("error unmarshalling data: %v", err)
			continue
		}
		// 客户端发来的包肯定是自己的，所以不需要设置senderID
		if packet.Uid == 0 {
			packet.Uid = c.id
		}
		c.ProcessMessage(packet.Uid, packet.Msg)
	}
}

func (c *WebSocketClient) Db() *gorm.DB {
	return c.hub.Db
}

func (c *WebSocketClient) Close(reason string) {
	if c.closed.Load() {
		return
	}
	c.closed.Store(true)
	c.logger.Printf("closing client connecting because: %s", reason)
	c.state.ClearResources()
	if c.state.Name() == "Connected" {
		// 如果是未登录而断开连接
		c.hub.ConnectedClients.Remove(c.id)
	} else {
		c.hub.LoginClients.Remove(c.id)
	}
	c.SetState(nil)
	_ = c.conn.Close()
	select {
	case <-c.sendChan:
	default:
	}
	close(c.sendChan)
}

func (c *WebSocketClient) Login(newID uint32) {
	c.hub.ConnectedClients.Remove(c.id)
	c.hub.LoginClients.Set(newID, c)
	c.id = newID
}

func (c *WebSocketClient) Hub() *internal.Hub {
	return c.hub
}
