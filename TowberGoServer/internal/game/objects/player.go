package objects

import (
	"TowberGoServer/internal"
	"TowberGoServer/internal/containers"
	"sync"
)

type Player struct {
	UserName     string
	UID          uint32
	Client       internal.ClientInterface
	Position     containers.Vector2
	EquippedPets []Pet
	Area         Area
	PetBagLock   sync.RWMutex
}
