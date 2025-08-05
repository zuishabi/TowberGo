extends Node

const packets := preload("res://packets.gd")

var PetList:Dictionary[int,BasePet] = {
	1:preload("res://classes/pets/buro.tres"),
}
var ExpList:PackedInt32Array = [20, 40, 80, 160, 320]

func msg_to_pet(msg:packets.PetMessage)->BasePet:
	if !PetList.has(msg.get_pet_id()):
		return null
	var new_pet:BasePet = PetList[msg.get_pet_id()].duplicate(true)
	new_pet.id = msg.get_id()
	new_pet.level = msg.get_level()
	new_pet.exp = msg.get_exp()
	var stats = msg.get_pet_stats()
	new_pet.max_hp = stats.get_max_hp()
	new_pet.hp = stats.get_hp()
	new_pet.max_mana = stats.get_max_mana()
	new_pet.mana = stats.get_mana()
	new_pet.defense = stats.get_defense()
	new_pet.intelligence = stats.get_intelligence()
	new_pet.strength = stats.get_strength()
	new_pet.speed = stats.get_speed()
	new_pet.skills.resize(4)
	for i in 4:
		new_pet.skills[i] = SkillManager.get_skill(msg.get_equipped_skills()[i])
	return new_pet
