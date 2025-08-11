extends Control


@onready var _h_box_container = $SkillList/HBoxContainer
@onready var _state_unit = $State/StateUnit
@onready var _state_unit_2 = $State/StateUnit2
@onready var _pet = $Pet
@onready var _pet_2 = $Pet2	
var round_end:bool
var attack_stats_array:Array[BattleManager.AttackStats]

func _ready():
	for i:SkillUnit in _h_box_container.get_children():
		i.select_skill.connect(_on_skill_unit_select_skill)


func update_pet(pet:BattleManager.BattlePet,number:int):
	if number == BattleManager.number:
		_state_unit.update_pet(pet)
		_pet.texture = pet.pet.pet_texture
	else:
		_state_unit_2.update_pet(pet)
		_pet_2.texture = pet.pet.pet_texture


func _on_skill_unit_select_skill(pos:int):
	lock_skills()
	var packet := GameManager.packets.Packet.new()
	var command := packet.new_battle_packet().new_command().new_attack()
	command.set_skill_pos(pos)
	WS.send(packet)


func unlock_skills():
	for i:SkillUnit in _h_box_container.get_children():
		i.unlock()


func lock_skills():
	for i:SkillUnit in _h_box_container.get_children():
		i.lock()


func process_attack_stats():
	for i in attack_stats_array:
		print("使用技能:",i.skill_id)
		print("受到物理伤害:",i.physical_damage)
		PetManager.sync_pet_stat(BattleManager.players[0].current_pet.pet,i.pet_stats[0])
		PetManager.sync_pet_stat(BattleManager.players[1].current_pet.pet,i.pet_stats[1])
		update_pet(BattleManager.players[0].current_pet,0)
		update_pet(BattleManager.players[1].current_pet,1)
	var packet := GameManager.packets.Packet.new()
	packet.new_battle_packet().new_round_confirm()
	WS.send(packet)
