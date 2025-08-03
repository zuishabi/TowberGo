package states

import (
	"TowberGoServer/internal"
	"TowberGoServer/internal/containers"
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/pkg/packets"
	"TowberGoServer/pkg/utils"
	"fmt"
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
		area := objects.AreaMgr.Get(message.PlayerEnterRequest.AreaName)
		if area == nil {
			fmt.Println("no current area")
			return
		}
		success, reason := area.CheckCanEnter(g.Player)
		rsp := utils.NewPlayerEnterAreaResponse(success, reason, area.Name())
		g.client.SocketSend(rsp)
		if g.Player.Area != nil {
			g.Player.Area.RemovePlayer(g.Player.UID)
		}
		area.AddPlayer(g.Player, message.PlayerEnterRequest.EntranceId)
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
	case *packets.Packet_MailRequest:
		g.handleMailRequest()
	case *packets.Packet_MailDelete:
		g.handleMailDelete(message.MailDelete.Id)
	case *packets.Packet_MailCollect:
		g.handleMailCollect(message.MailCollect.Id)
	case *packets.Packet_BagRequest:
		g.handleBagRequestMessage()
	case *packets.Packet_UseBagItemRequest:
		g.handleUseBagItemMessage(message.UseBagItemRequest)
	default:
		if g.Player.Area == nil {
			return
		}
		g.Player.Area.ProcessMessage(senderID, message)
	}
}

// 处理全局消息
func (g *InGame) handleChatMessage(senderID uint32, message *packets.Packet_Chat) {
	g.client.Hub().LoginClients.ForEach(func(id uint32, client internal.ClientInterface) {
		client.SocketSendAs(message, senderID)
	})
}

func (g *InGame) handleMailRequest() {
	mails := objects.MailManager.GetMails(g.Player.UID)
	for i := range mails {
		msg := utils.NewMailMessages(&mails[i])
		g.client.SocketSend(msg)
	}
}

// 处理删除邮件
func (g *InGame) handleMailDelete(id uint32) {
	objects.MailManager.DeleteMail(g.Player.UID, id)
}

// 处理收集邮件内容
func (g *InGame) handleMailCollect(id uint32) {
	rsp := &packets.Packet_MailCollectResponse{MailCollectResponse: &packets.MailCollectResponseMessage{
		Success: true,
		Reason:  "",
		Id:      id,
	}}
	if err := objects.MailManager.CollectMail(g.Player, id); err != nil {
		rsp.MailCollectResponse.Success = false
		rsp.MailCollectResponse.Reason = err.Error()
	}
	g.client.SocketSend(rsp)
}

// 发送背包物品
func (g *InGame) handleBagRequestMessage() {
	bags := objects.ItemManager.GetBags(g.Player)
	msg := utils.NewBagMessage(bags)
	g.client.SocketSend(msg)
}

// 处理使用背包物品
func (g *InGame) handleUseBagItemMessage(msg *packets.UseBagItemRequestMessage) {
	item := objects.BaseItem{
		ID:    msg.GetId(),
		Count: int(msg.GetCount()),
	}
	rsp := packets.Packet_UseBagItemResponse{}
	if err := item.Convert().Use(g.Player, int(msg.Count)); err != nil {
		rsp.UseBagItemResponse = &packets.UseBagItemResponseMessage{Reason: err.Error(), Success: false}
	} else {
		rsp.UseBagItemResponse = &packets.UseBagItemResponseMessage{Success: true}
	}
	g.client.SocketSend(&rsp)
}

func (g *InGame) OnExit() {

}

func (g *InGame) ClearResources() {
	if g.Player.Area != nil {
		g.Player.Area.RemovePlayer(g.Player.UID)
	}
}
