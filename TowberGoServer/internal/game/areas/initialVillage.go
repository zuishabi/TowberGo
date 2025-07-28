package areas

import (
	"TowberGoServer/internal/containers"
	"TowberGoServer/pkg/packets"
)

type InitialVillage struct {
	BaseArea
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
}

func (v *InitialVillage) Initialize() {
	v.BaseArea.Initialize(v)
}
