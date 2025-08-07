package petItems

import (
	"TowberGoServer/internal/game/objects"
	"errors"
)

type OrangeSugar struct {
	count int
}

func (o *OrangeSugar) Use(pet objects.Pet, count int) error {
	if pet == nil {
		return errors.New("pet error")
	}
	if objects.PetManager.AddExp(pet, 100*count) {
		return nil
	} else {
		return errors.New("current pet has reach top level")
	}
}

func (o *OrangeSugar) Count() int {
	return o.count
}

func (o *OrangeSugar) ID() uint32 {
	return 1
}

func (o *OrangeSugar) Name() string {
	return "OrangeSugar"
}

func (o *OrangeSugar) Clone(count int) objects.PetItem {
	return &OrangeSugar{count: count}
}
