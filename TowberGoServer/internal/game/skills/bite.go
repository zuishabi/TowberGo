package skills

import "TowberGoServer/internal/game/objects"

type Bite struct {
	coolDown int
}

func (b *Bite) Name() string {
	return "bite"
}

func (b *Bite) ID() uint32 {
	return 1
}

func (b *Bite) Use(self *objects.BattlePet, enemy *objects.BattlePet) []*objects.AttackInfo {
	return []*objects.AttackInfo{
		{
			PhysicalDamage: 10,
			MagicDamage:    0,
			Skill:          b.ID(),
		},
	}
}

func (b *Bite) Speed() int {
	return 1
}

func (b *Bite) Cost() int {
	return 0
}
