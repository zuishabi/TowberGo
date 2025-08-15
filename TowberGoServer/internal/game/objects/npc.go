package objects

import "TowberGoServer/internal/containers"

type NPC interface {
	ID() uint32
	Interact(player *Player)
	GetPos() containers.Vector2
}
