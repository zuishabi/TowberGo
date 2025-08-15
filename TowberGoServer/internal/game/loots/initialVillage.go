package loots

import "TowberGoServer/internal/game/objects"

type InitialVillageHead struct{}

func (i InitialVillageHead) getTableSize() int {
	return 1
}

func (i InitialVillageHead) getTable() []*objects.Loot {
	return []*objects.Loot{{ID: 1, Type: 1, Weight: 1}}
}

func (i InitialVillageHead) getCount() int {
	return 1
}
