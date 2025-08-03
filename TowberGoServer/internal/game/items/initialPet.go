package items

import (
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/pkg/packets"
)

type InitialPet struct {
	count int
}

func (i *InitialPet) Use(player *objects.Player, count int) error {
	openUI := packets.UiPacket_OpenUi{OpenUi: &packets.OpenUIMessage{Path: "initial_pet"}}
	player.Client.SocketSend(&packets.Packet_UiPacket{UiPacket: &packets.UiPacket{Msg: &openUI}})
	return nil
}

func (i *InitialPet) Count() int {
	return i.count
}

func (i *InitialPet) ID() uint32 {
	return 1
}

func (i *InitialPet) UseImmediately() bool {
	return false
}

func (i *InitialPet) Name() string {
	return "InitialPet"
}

func (i *InitialPet) Clone(count int) objects.Item {
	newItem := &InitialPet{count: count}
	return newItem
}
