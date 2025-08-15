package npcs

import (
	"TowberGoServer/internal/containers"
	"TowberGoServer/internal/game/objects"
	"fmt"
)

type InitialVillageHealer struct{}

func (i *InitialVillageHealer) ID() uint32 {
	return 1
}

func (i *InitialVillageHealer) Interact(player *objects.Player) {
	fmt.Println("交互成功")
}

func (i *InitialVillageHealer) GetPos() containers.Vector2 {
	return containers.Vector2{X: 20, Y: 50}
}
