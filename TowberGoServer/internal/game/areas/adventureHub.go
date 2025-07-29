package areas

import (
	"TowberGoServer/internal/containers"
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/pkg/packets"
)

type AdventureHub struct {
	BaseArea
}

func (a *AdventureHub) Initialize() {
	a.BaseArea.Initialize(a)
}

func (a *AdventureHub) GetEntrance(id uint32) containers.Vector2 {
	return containers.Vector2{X: 152, Y: 240}
}

func (a *AdventureHub) Name() string {
	return "AdventureHub"
}

func (a *AdventureHub) ProcessMessage(senderID uint32, message packets.Msg) {
	if a.BaseArea.ProcessMessage(senderID, message) {
		return
	}
}

func (a *AdventureHub) CheckCanEnter(player *objects.Player) (bool, string) {
	return true, ""
}
