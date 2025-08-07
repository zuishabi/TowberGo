package list

import (
	"TowberGoServer/internal/game/items"
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/internal/game/petItems"
)

var ItemList = map[uint32]objects.Item{
	1: &items.InitialPet{},
}

var PetItemList = map[uint32]objects.PetItem{
	1: &petItems.OrangeSugar{},
}
