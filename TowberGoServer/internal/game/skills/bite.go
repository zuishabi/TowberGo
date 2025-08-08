package skills

import "TowberGoServer/internal/game/objects"

type Bite struct {
	coolDown int
}

func (b *Bite) Name() string {
	return "bite"
}

func (b *Bite) ID() int {
	return 1
}

func (b *Bite) Use(self *objects.BattlePet, enemy *objects.BattlePet) []*objects.AttackInfo {
	return []*objects.AttackInfo{
		{
			From:           self,
			PhysicalDamage: 10,
			MagicDamage:    0,
		},
	}
}

func (b *Bite) Speed() int {
	return 1
}

func (b *Bite) CoolDown() int {
	return 0
}

func (b *Bite) Cost() int {
	return 0
}

func (b *Bite) SetCoolDown(num int) {
	b.coolDown = num
}

func (b *Bite) GetCoolDown() int {
	return b.coolDown
}
