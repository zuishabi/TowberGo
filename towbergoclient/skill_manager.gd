extends Node

var skill_list:Dictionary[int,BaseSkill]

func get_skill(id:int)->BaseSkill:
	if skill_list.has(id):
		return skill_list[id]
	return null
