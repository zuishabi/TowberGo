package objects

type Skill interface {
	Name() string
	ID() int
	Use(self *BattlePet, enemy *BattlePet) *AttackInfo
}

var SkillManager *SkillManagerStruct

type SkillManagerStruct struct {
	SkillList map[uint32]Skill
}
