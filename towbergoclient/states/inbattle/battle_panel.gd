extends Control


@onready var _h_box_container = $SkillList/HBoxContainer
@onready var _state_unit = $State/StateUnit
@onready var _state_unit_2 = $State/StateUnit2
@onready var _pet = $Pet
@onready var _pet_2 = $Pet2
var round_end:bool
var attack_stats_array:Array[BattleManager.AttackStats]
const shake_strength: float = 5.0
const shake_duration: float = 0.2
const shake_speed: float = 60.0

signal animation_finished

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
		pet_animation(i.number)
		await animation_finished
		PetManager.sync_pet_stat(BattleManager.players[0].current_pet.pet,i.pet_stats[0])
		PetManager.sync_pet_stat(BattleManager.players[1].current_pet.pet,i.pet_stats[1])
		update_pet(BattleManager.players[0].current_pet,0)
		update_pet(BattleManager.players[1].current_pet,1)
	attack_stats_array.clear()
	var packet := GameManager.packets.Packet.new()
	packet.new_battle_packet().new_round_confirm()
	WS.send(packet)


func pet_animation(number:int):
	print("number:",number)
	var tween := create_tween()
	var original_pos:Vector2
	if number == BattleManager.number:
		original_pos = _pet.position
		tween.tween_property(_pet,"position",_pet.position+Vector2.RIGHT*10,0.2)
		tween.tween_property(_pet,"position",original_pos,0.2)
		await tween.finished
		shake(_pet_2)
		return
	else:
		original_pos = _pet_2.position
		tween.tween_property(_pet_2,"position",_pet_2.position+Vector2.LEFT*10,0.2)
		tween.tween_property(_pet_2,"position",original_pos,0.2)
		await tween.finished
		shake(_pet)
		return

func shake(player:Sprite2D):
	# 创建或重用Tween节点
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# 保存原始位置
	var original_pos = player.global_position
	print(original_pos)
	
	# 创建震动效果 - 左右快速移动
	for i in range(0, shake_duration * shake_speed):
		var offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		tween.tween_property(player, "global_position", original_pos + offset, 1.0/shake_speed)
	
	# 最后回到原始位置
	tween.tween_property(player, "global_position", original_pos, 0.1)
	await tween.finished
	animation_finished.emit()
