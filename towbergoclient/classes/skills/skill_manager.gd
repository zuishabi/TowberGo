extends Node

var skill_list:Dictionary[int,BaseSkill] = {
	1:preload("res://classes/skills/Bite.tres"),
	2:preload("res://classes/skills/triple_strike.tres")
}

func get_skill(id:int)->BaseSkill:
	if skill_list.has(id):
		return skill_list[id]
	return null
