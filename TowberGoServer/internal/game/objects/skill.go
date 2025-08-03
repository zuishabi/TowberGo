package objects

type Skill interface {
	Name() string
	ID() int
	Use(self *Pet, enemy *Pet) *SkillSummary
}

type SkillSummary struct{}

var SkillManager *SkillManagerStruct

type SkillManagerStruct struct {
	SkillList map[uint32]Skill
}
