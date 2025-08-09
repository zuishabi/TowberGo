package pets

import (
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/internal/game/skills"
)

var BuroSkillList map[int]objects.Skill = map[int]objects.Skill{
	1: &skills.Bite{},
}

type Buro struct {
	exp            int
	stats          objects.Stats
	level          int
	equippedSkills [4]objects.Skill
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

func (b *Buro) Level() int {
	return b.level
}

func (b *Buro) LevelUp() {
	b.level += 1
	b.stats.MaxHP += 5
	b.stats.HP = b.stats.MaxHP
	b.stats.MaxMana += 3
	b.stats.Mana = b.stats.MaxMana
	b.stats.Defense += 2
	b.stats.Intelligence += 1
	b.stats.Strength += 5
	b.stats.Speed += 1
}

func (b *Buro) UnlockedSkillList() []objects.Skill {
	s := make([]objects.Skill, 0)
	for i := range BuroSkillList {
		if b.level >= i {
			s = append(s, BuroSkillList[i])
		}
	}
	return s
}

func (b *Buro) EquippedSkills() [4]objects.Skill {
	return b.equippedSkills
}

func (b *Buro) Initialize(exp int, equippedSkills []uint32, stats *objects.Stats, owner *objects.Player) objects.Pet {
	res := Buro{
		exp:            exp,
		stats:          *stats,
		level:          objects.ConvertExpToLevel(exp),
		equippedSkills: [4]objects.Skill{},
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
		HP:           50,
		MaxMana:      60,
		Mana:         60,
		Strength:     60,
		Intelligence: 20,
		Speed:        60,
		Defense:      10,
	}
}

func (b *Buro) Owner() *objects.Player {
	return b.owner
}

func (b *Buro) SetExp(exp int) {
	b.exp = exp
}

func (b *Buro) GetEvent(event int, self bool, battleRoom *objects.BattleRoom) {

}
