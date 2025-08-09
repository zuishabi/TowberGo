package areas

import (
	"TowberGoServer/internal/containers"
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/pkg/packets"
)

type InitialVillage struct {
	objects.BaseArea
}

func (v *InitialVillage) GetEntrance(id uint32) containers.Vector2 {
	if id == 0 {
		return containers.Vector2{X: 100, Y: 100}
	}
	return containers.Vector2{X: 184, Y: 145}
}

func (v *InitialVillage) Name() string {
	return "InitialVillage"
}

func (v *InitialVillage) ProcessMessage(senderID uint32, message packets.Msg) {
	if v.BaseArea.ProcessMessage(senderID, message) {
		return
	}
	switch message := message.(type) {
	
	}
}

func (v *InitialVillage) Initialize() {
	v.BaseArea.Initialize(v)
}

func (v *InitialVillage) CheckCanEnter(player *objects.Player) (bool, string) {
	return true, ""
}
