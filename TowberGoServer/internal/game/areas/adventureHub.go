package areas

import (
	"TowberGoServer/internal/containers"
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/pkg/packets"
	"fmt"
)

type AdventureHub struct {
	objects.BaseArea
	rooms *BattleWaitRooms
}

func (a *AdventureHub) Initialize() {
	a.BaseArea.Initialize(a)
	a.rooms = &BattleWaitRooms{waitMap: make(map[uint32]*BattleUnit)}
	go a.rooms.Start()
}

func (a *AdventureHub) GetEntrance(id uint32) containers.Vector2 {
	return containers.Vector2{X: 152, Y: 240}
}

func (a *AdventureHub) Name() string {
	return "AdventureHub"
}

func (a *AdventureHub) ProcessMessage(sender *objects.Player, message packets.Msg) {
	if a.BaseArea.ProcessMessage(sender, message) {
		return
	}
	switch message := message.(type) {
	case *packets.Packet_BattleRequest:
		target, ok := a.Players.Get(message.BattleRequest.GetTarget())
		if !ok {
			deny := &packets.Packet_DenyResponse{DenyResponse: &packets.DenyResponseMessage{Reason: "error request"}}
			sender.Client.SocketSend(deny)
			return
		}
		// 创建房间，并向对方发送请求
		a.rooms.CreateRoom(sender, target)
	case *packets.Packet_BattleInvitingResponse:
		fmt.Println("收到战斗邀请回应,", message.BattleInvitingResponse)
		if message.BattleInvitingResponse.Accepted {
			a.rooms.AcceptRoom(message.BattleInvitingResponse.RoomID, sender.UID)
		} else {
			a.rooms.RejectRoom(message.BattleInvitingResponse.RoomID)
		}
	}
}

func (a *AdventureHub) CheckCanEnter(player *objects.Player) (bool, string) {
	return true, ""
}
