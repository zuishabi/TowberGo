package objects

type Skill interface {
	Name() string
	ID() uint32
	Use(self *BattlePet, enemy *BattlePet) []*AttackInfo
	Speed() int
	Cost() int
}

var SkillManager *SkillManagerStruct

type SkillManagerStruct struct {
	SkillList map[uint32]Skill
}
