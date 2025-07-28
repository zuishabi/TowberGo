package states

import (
	"TowberGoServer/internal"
	"TowberGoServer/internal/containers"
	"TowberGoServer/internal/game/areas"
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/pkg/packets"
)

type InGame struct {
	Player *objects.Player
	client internal.ClientInterface
}

func (g *InGame) Name() string {
	return "InGame"
}

// SetClient 将客户端注入到状态中
func (g *InGame) SetClient(client internal.ClientInterface) {
	g.client = client
	g.Player.Client = client
}

// OnEnter 每次状态改变时调用
func (g *InGame) OnEnter() {

}

func (g *InGame) HandleMessage(senderID uint32, message packets.Msg) {
	switch message := message.(type) {
	case *packets.Packet_PlayerEnterRequest:
		// 处理玩家加入区域请求，首先将玩家移除当前区域
		if g.Player.Area != nil {
			g.Player.Area.RemovePlayer(g.Player.UID)
		}
		area := areas.AreaMgr.Get(message.PlayerEnterRequest.AreaName)
		if area != nil {
			area.AddPlayer(g.Player, message.PlayerEnterRequest.EntranceId)
		}
	case *packets.Packet_Chat:
		if message.Chat.Type == 1 {
			g.handleChatMessage(senderID, message)
		} else {
			g.Player.Area.ProcessMessage(senderID, message)
		}
	case *packets.Packet_PlayerMovement:
		g.Player.Position = containers.Vector2{
			X: message.PlayerMovement.ToX,
			Y: message.PlayerMovement.ToY,
		}
		g.Player.Area.ProcessMessage(senderID, message)
	default:
		g.Player.Area.ProcessMessage(senderID, message)
	}
}

// 处理全局消息
func (g *InGame) handleChatMessage(senderID uint32, message *packets.Packet_Chat) {
	g.client.Hub().LoginClients.ForEach(func(id uint32, client internal.ClientInterface) {
		client.SocketSendAs(message, senderID)
	})
}

func (g *InGame) OnExit() {

}

func (g *InGame) ClearResources() {
	if g.Player.Area != nil {
		g.Player.Area.RemovePlayer(g.Player.UID)
	}
}
