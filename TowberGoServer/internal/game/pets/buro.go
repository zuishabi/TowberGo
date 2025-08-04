package pets

import (
	"TowberGoServer/internal/game/objects"
)

var BuroSkillList map[int]objects.Skill = map[int]objects.Skill{}

type Buro struct {
	exp            int
	stats          objects.Stats
	level          int
	equippedSkills []objects.Skill
	owner          *objects.Player
	id             uint64
}

func (b *Buro) PetID() uint32 {
	return 1
}

func (b *Buro) ID() uint64 {
	return b.id
}

func (b *Buro) SetID(id uint64) {
	b.id = id
}

func (b *Buro) Name() string {
	return "Buro"
}

func (b *Buro) SkillList() map[int]objects.Skill {
	return BuroSkillList
}

func (b *Buro) Exp() int {
	return b.exp
}

func (b *Buro) AddExp(exp int) bool {
	flag := false
	if b.Exp() == objects.MaxExp {
		return false
	}
	if b.Exp()+exp >= objects.MaxExp {
		b.exp = objects.MaxExp
	} else {
		b.exp += exp
	}
	for b.exp >= objects.LevelList[b.level-1] {
		flag = true
		b.LevelUp()
	}
	return flag
}

func (b *Buro) Level() int {
	return b.level
}

func (b *Buro) LevelUp() {
	b.level += 1
	b.stats.MaxHP += 5
	b.stats.Defense += 2
	b.stats.Intelligence += 1
	b.stats.Strength += 5
	b.stats.Speed += 1
}

func (b *Buro) UnlockedSkillList() []objects.Skill {
	skills := make([]objects.Skill, 0)
	for i := range BuroSkillList {
		if b.level >= i {
			skills = append(skills, BuroSkillList[i])
		}
	}
	return skills
}

func (b *Buro) EquippedSkills() []objects.Skill {
	return b.equippedSkills
}

func (b *Buro) Initialize(exp int, equippedSkills []uint32, stats *objects.Stats, owner *objects.Player) objects.Pet {
	if exp == 0 {
		// 相当于生成一个宠物
		s := b.BaseStats()
		stats = &s
		// TODO 在这里初始化技能
	}
	res := Buro{
		exp:            exp,
		stats:          *stats,
		level:          objects.ConvertExpToLevel(exp),
		equippedSkills: make([]objects.Skill, 4),
		owner:          owner,
	}
	if len(equippedSkills) > 4 {
		equippedSkills = equippedSkills[:4]
	}
	for i := range equippedSkills {
		if equippedSkills[i] != 0 {
			res.equippedSkills[i] = objects.SkillManager.SkillList[equippedSkills[i]]
		}
	}
	return &res
}

func (b *Buro) Stats() *objects.Stats {
	return &b.stats
}

func (b *Buro) BaseStats() objects.Stats {
	return objects.Stats{
		MaxHP:        50,
		Strength:     60,
		Intelligence: 20,
		Speed:        60,
		Defense:      10,
	}
}

func (b *Buro) Owner() *objects.Player {
	return b.owner
}
