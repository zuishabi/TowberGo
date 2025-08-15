package skills

import "TowberGoServer/internal/game/objects"

type TripleStrike struct{}

func (t TripleStrike) Name() string {
	return "TripleStrike"
}

func (t TripleStrike) ID() uint32 {
	return 2
}

func (t TripleStrike) Use(self *objects.BattlePet, enemy *objects.BattlePet) []*objects.AttackInfo {
	return []*objects.AttackInfo{
		{
			PhysicalDamage: 20,
			MagicDamage:    0,
			Skill:          t.ID(),
		},
		{
			PhysicalDamage: 20,
			MagicDamage:    0,
			Skill:          t.ID(),
		},
		{
			PhysicalDamage: 20,
			MagicDamage:    0,
			Skill:          t.ID(),
		},
	}
}

func (t TripleStrike) Speed() int {
	return 2
}

func (t TripleStrike) Cost() int {
	return 10
}
