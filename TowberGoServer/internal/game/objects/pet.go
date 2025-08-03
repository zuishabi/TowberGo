package objects

type Pet interface {
	ID() uint32
	Name() string
	SkillList() []Skill
}
