extends Control

@onready var _skill_list = $LearnSkill/MarginContainer/VBoxContainer/ScrollContainer/SkillList
const SKILL_SLOT = preload("res://classes/units/skill_slot/skill_slot.tscn")
@onready var _skill_choose = $SkillChoose
@onready var _skill_detail = %SkillDetail
var current_pet:BasePet
var chosen_skill:BaseSkill

func _ready():
	_skill_choose.hide()

func update(pet:BasePet):
	current_pet = pet
	_skill_choose.hide()
	for i in _skill_list.get_children():
		i.queue_free()
	var unlocked_skills := pet.skill_list.duplicate()
	for i in unlocked_skills:
		if i > pet.level:
			unlocked_skills.erase(i)
		if pet.skills.has(unlocked_skills[i]):
			unlocked_skills.erase(i)
	for i in unlocked_skills:
		var new_slot := SKILL_SLOT.instantiate()
		_skill_list.add_child(new_slot)
		new_slot.update(unlocked_skills[i])
		new_slot.click_skill_slot.connect(learn_skill)
		new_slot.update_skill_detail.connect(update_skill_detail)

func learn_skill(skill:BaseSkill):
	_skill_choose.show()
	chosen_skill = skill

func _on_exit_pressed():
	self.hide()

func _on_cancel_pressed():
	_skill_choose.hide()

func update_skill_detail(skill:BaseSkill,flag:bool):
	if flag:
		_skill_detail.update(skill)
	else:
		_skill_detail.update_hide()

func _on_slot_1_pressed():
	var packet := GameManager.packets.Packet.new()
	var req := packet.new_learn_skill_request()
	req.set_pet_id(current_pet.id)
	req.set_position(0)
	req.set_skill_id(chosen_skill.skill_id)
	WS.send(packet)
	var update := GameManager.packets.Packet.new()
	update.new_equipped_pet_info_request().set_id(current_pet.id)
	WS.send(update)
	self.hide()

func _on_slot_1_mouse_entered():
	_skill_detail.update(current_pet.skills[0])

func _on_slot_2_pressed():
	var packet := GameManager.packets.Packet.new()
	var req := packet.new_learn_skill_request()
	req.set_pet_id(current_pet.id)
	req.set_position(1)
	req.set_skill_id(chosen_skill.skill_id)
	WS.send(packet)
	var update := GameManager.packets.Packet.new()
	update.new_equipped_pet_info_request().set_id(current_pet.id)
	WS.send(update)
	self.hide()

func _on_slot_2_mouse_entered():
	_skill_detail.update(current_pet.skills[1])

func _on_slot_3_pressed():
	var packet := GameManager.packets.Packet.new()
	var req := packet.new_learn_skill_request()
	req.set_pet_id(current_pet.id)
	req.set_position(2)
	req.set_skill_id(chosen_skill.skill_id)
	WS.send(packet)
	var update := GameManager.packets.Packet.new()
	update.new_equipped_pet_info_request().set_id(current_pet.id)
	WS.send(update)
	self.hide()

func _on_slot_3_mouse_entered():
	_skill_detail.update(current_pet.skills[2])

func _on_slot_4_pressed():
	var packet := GameManager.packets.Packet.new()
	var req := packet.new_learn_skill_request()
	req.set_pet_id(current_pet.id)
	req.set_position(3)
	req.set_skill_id(chosen_skill.skill_id)
	WS.send(packet)
	var update := GameManager.packets.Packet.new()
	update.new_equipped_pet_info_request().set_id(current_pet.id)
	WS.send(update)
	self.hide()

func _on_slot_4_mouse_entered():
	_skill_detail.update(current_pet.skills[3])

func _mouse_exit():
	_skill_detail.update_hide()
