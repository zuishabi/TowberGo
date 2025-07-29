package objects

import (
	"TowberGoServer/internal/containers"
	"TowberGoServer/pkg/packets"
)

type Area interface {
	GetEntrance(id uint32) containers.Vector2
	Name() string
	AddPlayer(player *Player, id uint32)
	RemovePlayer(uid uint32)
	BroadcastArea(packet *packets.Packet, except bool)
	// ProcessMessage 将消息传递给area处理
	ProcessMessage(uid uint32, packet packets.Msg)
	Initialize()
	CheckCanEnter(player *Player) (bool, string)
}
