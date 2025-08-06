package skills

import "TowberGoServer/internal/game/objects"

type Bite struct{}

func (b *Bite) Name() string {
	return "bite"
}

func (b *Bite) ID() int {
	return 1
}

func (b *Bite) Use(self *objects.BattlePet, enemy *objects.BattlePet) *objects.AttackInfo {
	return &objects.AttackInfo{
		From:           self,
		PhysicalDamage: 10,
	}
}
