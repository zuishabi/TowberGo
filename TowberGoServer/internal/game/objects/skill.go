package objects

type Skill interface {
	Name() string
	ID() int
	Use(self *BattlePet, enemy *BattlePet) []*AttackInfo
	Speed() int
	CoolDown() int
	Cost() int
	SetCoolDown(num int)
	GetCoolDown() int
}

var SkillManager *SkillManagerStruct

type SkillManagerStruct struct {
	SkillList map[uint32]Skill
}
