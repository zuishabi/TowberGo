extends Node

const packets := preload("res://packets.gd")

var PetList:Dictionary[int,BasePet] = {
	1:preload("res://classes/pets/buro.tres"),
}
var ExpList:PackedInt32Array = [20, 40, 80, 160, 320, 480, 660, 860, 1080, 1024]

class Stats:
	var max_hp:int
	var hp:int
	var max_mana:int
	var mana:int
	var strength:int
	var intelligence:int
	var speed:int
	var defense:int

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

func sync_pet_stat(pet:BasePet,stats:Stats):
	pet.defense = stats.defense
	pet.hp = stats.hp
	pet.max_hp = stats.max_hp
	pet.mana = stats.mana
	pet.max_mana = stats.max_mana
	pet.strength = stats.strength
	pet.speed = stats.speed
	pet.intelligence = stats.intelligence

func msg_to_stats(msg:packets.PetStatsMessage)->Stats:
	var res:Stats = Stats.new()
	res.defense = msg.get_defense()
	res.hp = msg.get_hp()
	res.intelligence = msg.get_intelligence()
	res.mana = msg.get_mana()
	res.max_hp = msg.get_max_hp()
	res.max_mana = msg.get_max_mana()
	res.speed = msg.get_speed()
	res.strength = msg.get_strength()
	return res
