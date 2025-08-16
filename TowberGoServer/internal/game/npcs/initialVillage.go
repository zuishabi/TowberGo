package npcs

import (
	"TowberGoServer/internal/containers"
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/pkg/packets"
)

type InitialVillageHeader struct {
	BattleEndChanLevel1 chan *objects.BattleSummary
	BattleEndChanLevel2 chan *objects.BattleSummary
}

func (i *InitialVillageHeader) ID() uint32 {
	return 1
}

func (i *InitialVillageHeader) Interact(player *objects.Player) {
	msg := &packets.Packet_UiPacket{UiPacket: &packets.UiPacket{Msg: &packets.UiPacket_OpenUi{
		OpenUi: &packets.OpenUIMessage{Path: "initial_village_header"},
	}}}
	player.Client.SocketSend(msg)
}

func (i *InitialVillageHeader) GetPos() containers.Vector2 {
	return containers.Vector2{X: 230, Y: 140}
}

func (i *InitialVillageHeader) ProcessInteractPacket(player *objects.Player, msg *packets.NPCInteractPacket) {
}

func (i *InitialVillageHeader) Initialize() {
	i.BattleEndChanLevel1 = make(chan *objects.BattleSummary, 5)
	i.BattleEndChanLevel2 = make(chan *objects.BattleSummary, 5)
	go func() {
		for {
			select {
			case summary := <-i.BattleEndChanLevel1:
				if summary.Winner != nil {
					_ = objects.ItemManager.AddItem(summary.Winner, 1, 2)
				}
			case summary := <-i.BattleEndChanLevel2:
				if summary.Winner != nil {
					_ = objects.ItemManager.AddItem(summary.Winner, 1, 4)
				}
			}
		}
	}()
}

// InitialVillageHealer 治疗
type InitialVillageHealer struct{}

func (i *InitialVillageHealer) ID() uint32 {
	return 2
}

func (i *InitialVillageHealer) Interact(player *objects.Player) {
	msg := &packets.Packet_UiPacket{UiPacket: &packets.UiPacket{Msg: &packets.UiPacket_OpenUi{
		OpenUi: &packets.OpenUIMessage{Path: "healer"},
	}}}
	player.Client.SocketSend(msg)
}

func (i *InitialVillageHealer) GetPos() containers.Vector2 {
	return containers.Vector2{X: 260, Y: 140}
}

func (i *InitialVillageHealer) ProcessInteractPacket(player *objects.Player, msg *packets.NPCInteractPacket) {
	switch msg.Msg.(type) {
	case *packets.NPCInteractPacket_Heal:
		player.PetBagLock.Lock()
		defer player.PetBagLock.Unlock()
		for _, v := range player.EquippedPets {
			if v != nil {
				v.Stats().HP = v.Stats().MaxHP
			}
		}
	}
}

func (i *InitialVillageHealer) Initialize() {

}
