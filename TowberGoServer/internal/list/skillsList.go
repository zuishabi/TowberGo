package list

import (
	"TowberGoServer/internal/game/objects"
	"TowberGoServer/internal/game/skills"
)

var SkillsList = map[uint32]objects.Skill{
	1: &skills.Bite{},
	2: &skills.TripleStrike{},
}
