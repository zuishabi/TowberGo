package list

import (
	"TowberGoServer/internal/game/items"
	"TowberGoServer/internal/game/objects"
)

var ItemList = map[uint32]objects.Item{
	1: &items.InitialPet{},
}

var PetItemList = map[uint32]objects.PetItem{}
