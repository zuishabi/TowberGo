package objects

import (
	"TowberGoServer/internal/containers"
	"TowberGoServer/pkg/packets"
)

type NPC interface {
	ID() uint32
	Interact(player *Player)
	GetPos() containers.Vector2
	ProcessInteractPacket(player *Player, packet *packets.NPCInteractPacket)
	Initialize()
}
