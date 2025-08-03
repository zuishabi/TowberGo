package list

import (
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/internal/game/pets"
)

var PetList = map[uint32]objects.Pet{
	1: &pets.Buro{},
}
