package states

import (
	"TowberGoServer/internal"
	"TowberGoServer/internal/db"
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/pkg/packets"
	"fmt"
	"log"
)

type Connected struct {
	client internal.ClientInterface
	logger *log.Logger
}

func (c *Connected) Name() string {
	return "Connected"
}

func (c *Connected) SetClient(client internal.ClientInterface) {
	c.client = client
	loggingPrefix := fmt.Sprintf("Client %d [%s]: ", client.ID(), c.Name())
	c.logger = log.New(log.Writer(), loggingPrefix, log.LstdFlags)
}

func (c *Connected) OnEnter() {}

func (c *Connected) HandleMessage(senderId uint32, message packets.Msg) {
	switch message := message.(type) {
	case *packets.Packet_LoginRequest:
		c.handleLoginRequest(senderId, message)
	case *packets.Packet_RegisterRequest:
		c.handleRegisterRequest(senderId, message)
	}
}

func (c *Connected) OnExit() {}

func (c *Connected) handleLoginRequest(senderID uint32, message *packets.Packet_LoginRequest) {
	userInfo := db.UserInfo{}
	if err := c.client.Db().Where("user_name = ? and password = ?", message.LoginRequest.Username, message.LoginRequest.Password).
		First(&userInfo).Error; err != nil {
		c.client.SocketSend(&packets.Packet_DenyResponse{DenyResponse: &packets.DenyResponseMessage{Reason: "error username or password"}})
		return
	}
	if _, exists := c.client.Hub().LoginClients.Get(userInfo.ID); exists {
		c.client.SocketSend(&packets.Packet_DenyResponse{DenyResponse: &packets.DenyResponseMessage{Reason: "the player has logged in"}})
		return
	}
	c.client.SocketSend(&packets.Packet_LoginSuccess{LoginSuccess: &packets.LoginSuccessMessage{
		Username: userInfo.UserName,
		Uid:      userInfo.ID,
	}})
	c.client.Login(userInfo.ID)
	// 转换状态
	c.client.SetState(&InGame{Player: &objects.Player{
		UserName:     userInfo.UserName,
		UID:          userInfo.ID,
		EquippedPets: [5]objects.Pet{},
	}})
}

func (c *Connected) handleRegisterRequest(senderID uint32, message *packets.Packet_RegisterRequest) {
	userInfo := db.UserInfo{
		UserName: message.RegisterRequest.Username,
		Password: message.RegisterRequest.Password,
	}
	if err := c.client.Db().Where("user_name = ?", userInfo.UserName).First(&db.UserInfo{}).Error; err == nil {
		c.client.SocketSend(&packets.Packet_DenyResponse{DenyResponse: &packets.DenyResponseMessage{Reason: "the username has already existed"}})
		return
	}
	c.client.Db().Create(&userInfo)

	// 创建玩家的宠物背包
	petBag := db.EquippedPets{UID: userInfo.ID}
	c.client.Db().Create(&petBag)

	c.client.SocketSend(&packets.Packet_OkResponse{OkResponse: &packets.OKResponseMessage{}})
	objects.MailManager.SendMail(userInfo.ID, &objects.Mail{
		Title:   "new player's reward",
		Content: "welcome to the xxx land,these are the towbers you can choose one as your assistant",
		Items:   []objects.MailItem{{ID: 1, Count: 1, Type: 2}, {ID: 1, Count: 2, Type: 1}},
		Sender:  "admin",
	})
	objects.MailManager.SendMail(userInfo.ID, &objects.Mail{
		Title:   "welcome to this land",
		Content: "welcome to this land",
		Sender:  "admin",
	})
}

func (c *Connected) ClearResources() {

}
