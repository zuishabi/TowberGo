package areas

import (
	"TowberGoServer/internal/containers"
	"TowberGoServer/internal/game/npcs"
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/pkg/packets"
)

type InitialVillage struct {
	objects.BaseArea
	npcs []objects.NPC
}

func (v *InitialVillage) GetEntrance(id uint32) containers.Vector2 {
	if id == 0 {
		return containers.Vector2{X: 100, Y: 100}
	}
	return containers.Vector2{X: 184, Y: 145}
}

func (v *InitialVillage) Name() string {
	return "InitialVillage"
}

func (v *InitialVillage) ProcessMessage(sender *objects.Player, message packets.Msg) {
	if v.BaseArea.ProcessMessage(sender, message) {
		return
	}
	switch message := message.(type) {
	case *packets.Packet_BattleRequest:
		message.BattleRequest.GetTarget()
		packet := packets.Packet_DenyResponse{DenyResponse: &packets.DenyResponseMessage{Reason: "this area cannot battle"}}
		sender.Client.SocketSend(&packet)
	case *packets.Packet_InteractNpcRequest:
		for _, b := range v.npcs {
			if b.ID() == message.InteractNpcRequest.Id {
				b.Interact(sender)
				sender.CurrentInteractingNPC = b
				return
			}
		}
	}
}

func (v *InitialVillage) Initialize() {
	v.npcs = []objects.NPC{&npcs.InitialVillageHealer{}, &npcs.InitialVillageHeader{}}
	for _, j := range v.npcs {
		j.Initialize()
	}
	v.BaseArea.Initialize(v)
}

func (v *InitialVillage) CheckCanEnter(player *objects.Player) (bool, string) {
	return true, ""
}

func (v *InitialVillage) GetNPCs() []objects.NPC {
	return v.npcs
}
