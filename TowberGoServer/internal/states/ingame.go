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
	Player     *objects.Player
	client     internal.ClientInterface
	hasEntered bool
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
	msg := packets.Packet_SyncState{SyncState: &packets.SyncState{State: 2}}
	g.client.SocketSend(&msg)
	if !g.hasEntered {
		g.Player.EquippedPets = objects.PetManager.GetPetBag(g.Player)
		g.hasEntered = true
		g.HandleMessage(0, &packets.Packet_PlayerEnterRequest{PlayerEnterRequest: &packets.PlayerEnterAreaRequestMessage{
			AreaName:   "InitialVillage",
			EntranceId: 0,
		}})
	} else {
		rsp := utils.NewPlayerEnterAreaResponse(true, "", g.Player.Area.Name())
		g.client.SocketSend(rsp)
	}
}

func (g *InGame) OnExit() {

}

func (g *InGame) ClearResources() {
	if g.Player.Area != nil {
		g.Player.Area.RemovePlayer(g.Player.UID)
	}
	for _, v := range g.Player.EquippedPets {
		objects.PetManager.SavePet(g.Player, v)
	}
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
		if g.Player.Area != nil {
			g.Player.Area.RemovePlayer(g.Player.UID)
		}
		area.AddPlayer(g.Player, message.PlayerEnterRequest.EntranceId)
		rsp := utils.NewPlayerEnterAreaResponse(success, reason, area.Name())
		g.client.SocketSend(rsp)
	case *packets.Packet_Chat:
		if message.Chat.Type == 1 {
			g.handleChatMessage(senderID, message)
		} else {
			g.Player.Area.ProcessMessage(g.Player, message)
		}
	case *packets.Packet_PlayerMovement:
		g.Player.Position = containers.Vector2{
			X: message.PlayerMovement.ToX,
			Y: message.PlayerMovement.ToY,
		}
		g.Player.Area.ProcessMessage(g.Player, message)
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
	case *packets.Packet_UiPacket:
		g.handleUiPacket(senderID, message.UiPacket.Msg)
	case *packets.Packet_SavePet:
		g.handleSavePet()
	case *packets.Packet_PetBagRequest:
		g.handlePetBagRequest()
	case *packets.Packet_LearnSkillRequest:
		g.handleLearnSkill(message.LearnSkillRequest)
	case *packets.Packet_PetItemBagRequest:
		g.handlePetItemBagRequest()
	case *packets.Packet_UsePetItemRequest:
		g.handleUsePetItemRequest(message.UsePetItemRequest)
	case *packets.Packet_EquippedPetInfoRequest:
		g.handleEquippedPetInfoRequest(message.EquippedPetInfoRequest.Id)
	case *packets.Packet_StartBattle:
		g.client.SocketSend(message)
	case *packets.Packet_GetAreaRequest:
		g.Player.Area.GetAreaInfo(g.Player)
	case *packets.Packet_NpcInteract:
		if g.Player.CurrentInteractingNPC != nil {
			g.Player.CurrentInteractingNPC.ProcessInteractPacket(g.Player, message.NpcInteract)
		}
	default:
		if g.Player.Area == nil {
			return
		}
		g.Player.Area.ProcessMessage(g.Player, message)
	}
}

// 处理全局消息
func (g *InGame) handleChatMessage(senderID uint32, message *packets.Packet_Chat) {
	g.client.Hub().LoginClients.ForEach(func(id uint32, client internal.ClientInterface) {
		if client == nil {
			return
		}
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

// 当收到来自hub的保存宠物信息的广播时调用
func (g *InGame) handleSavePet() {
	for i := range g.Player.EquippedPets {
		if g.Player.EquippedPets[i] != nil {
			objects.PetManager.SavePet(g.Player, g.Player.EquippedPets[i])
		}
	}
}

func (g *InGame) handlePetBagRequest() {
	g.Player.PetBagLock.RLock()
	defer g.Player.PetBagLock.RUnlock()
	pets := make([]*packets.PetMessage, 5)
	for i, v := range g.Player.EquippedPets {
		if v == nil {
			continue
		}
		equippedSkills := make([]uint32, 4)
		for a, b := range v.EquippedSkills() {
			if b == nil {
				continue
			}
			equippedSkills[a] = uint32(b.ID())
		}
		stats := packets.PetStatsMessage{
			MaxHp:        int64(v.Stats().MaxHP),
			Hp:           int64(v.Stats().HP),
			MaxMana:      int64(v.Stats().MaxMana),
			Mana:         int64(v.Stats().Mana),
			Strength:     int64(v.Stats().Strength),
			Intelligence: int64(v.Stats().Intelligence),
			Speed:        int64(v.Stats().Speed),
			Defense:      int64(v.Stats().Defense),
		}
		fmt.Println(v.Stats())
		pets[i] = &packets.PetMessage{
			PetId:          v.PetID(),
			Id:             v.ID(),
			Exp:            int64(v.Exp()),
			Level:          int64(v.Level()),
			EquippedSkills: equippedSkills,
			PetStats:       &stats,
		}
	}
	response := packets.Packet_PetBagResponse{PetBagResponse: &packets.PetBagResponseMessage{Pet: pets}}
	g.client.SocketSend(&response)
}

func (g *InGame) handleLearnSkill(msg *packets.LearnSkillRequestMessage) {
	g.Player.PetBagLock.RLock()
	defer g.Player.PetBagLock.RUnlock()
	rsp := &packets.LearnSkillResponseMessage{Success: true}
	for i, v := range g.Player.EquippedPets {
		if v.ID() == msg.PetId {
			if err := objects.PetManager.LearnSkill(v, msg.GetSkillId(), int(msg.GetPosition())); err != nil {
				rsp.Success = false
				rsp.Reason = err.Error()
			}
			break
		}
		if i == 4 {
			rsp.Success = false
			rsp.Reason = "no such pet"
		}
	}
	g.client.SocketSend(&packets.Packet_LearnSkillResponse{LearnSkillResponse: rsp})
}

// 发送宠物背包中的物品
func (g *InGame) handlePetItemBagRequest() {
	bags := objects.PetItemManager.GetBags(g.Player)
	g.client.SocketSend(utils.NewPetItemBagMessage(bags))
}

func (g *InGame) handleUsePetItemRequest(msg *packets.UsePetItemRequestMessage) {
	i := objects.BasePetItem{
		Count: int(msg.Count),
		ID:    msg.GetId(),
	}
	item := i.Convert()
	g.Player.PetBagLock.RLock()
	defer g.Player.PetBagLock.RUnlock()
	var pet objects.Pet
	for _, v := range g.Player.EquippedPets {
		if v != nil && v.ID() == msg.PetId {
			pet = v
			break
		}
	}
	rsp := &packets.UsePetItemResponseMessage{Success: true}
	if err := objects.PetItemManager.DeleteItem(g.Player, item.ID(), item.Count()); err != nil {
		rsp.Success = false
		rsp.Reason = err.Error()
		g.client.SocketSend(&packets.Packet_UsePetItemResponse{UsePetItemResponse: rsp})
		return
	}
	if err := item.Use(pet, item.Count()); err != nil {
		rsp.Success = false
		rsp.Reason = err.Error()
		objects.PetItemManager.CompensateItem(g.Player, item.ID(), item.Count())
		g.client.SocketSend(&packets.Packet_UsePetItemResponse{UsePetItemResponse: rsp})
	} else {
		g.client.SocketSend(&packets.Packet_UsePetItemResponse{UsePetItemResponse: rsp})
	}
}

func (g *InGame) handleEquippedPetInfoRequest(id uint64) {
	g.Player.PetBagLock.RLock()
	defer g.Player.PetBagLock.RUnlock()
	for _, v := range g.Player.EquippedPets {
		if v != nil && v.ID() == id {
			pet := v
			petMsg := utils.NewPetMessage(pet)
			g.client.SocketSend(&packets.Packet_EquippedPetInfoResponse{EquippedPetInfoResponse: &packets.EquippedPetInfoResponseMessage{
				Id:  id,
				Pet: petMsg,
			}})
			return
		}
	}

	// 如果需要更新的宠物不在背包中，则刷新玩家背包
	g.HandleMessage(0, &packets.Packet_PetBagRequest{PetBagRequest: &packets.PetBagRequestMessage{}})
}

//---------------------------------------------------------处理ui信息----------------------------------------------------

func (g *InGame) handleUiPacket(senderID uint32, msg packets.UIMsg) {
	switch message := msg.(type) {
	case *packets.UiPacket_InitialPetRequest:
		g.handleInitialPetRequest(message.InitialPetRequest)
	}
}

func (g *InGame) handleInitialPetRequest(msg *packets.InitialPetRequestMessage) {
	if err := objects.ItemManager.DeleteItem(g.Player, 1, 1); err != nil {
		g.client.SocketSend(&packets.Packet_DenyResponse{DenyResponse: &packets.DenyResponseMessage{Reason: err.Error()}})
		return
	}
	objects.PetManager.CreatePet(g.Player, msg.RequestId)
}
