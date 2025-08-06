class_name SkillSlot
extends PanelContainer

var current_skill:BaseSkill
signal update_skill_detail(skill:BaseSkill,flag:bool)
signal click_skill_slot(skill:BaseSkill)
const SWORD = preload("res://assets/items/sword.tres")
const WAND = preload("res://assets/items/wand.tres")
@onready var _type = $VBoxContainer/HBoxContainer/Type
@onready var _label = $VBoxContainer/HBoxContainer/Label
@onready var _speed_text = $VBoxContainer/HBoxContainer2/SpeedText
@onready var _cost_text = $VBoxContainer/HBoxContainer2/CostText
@onready var h_box_container_2 = $VBoxContainer/HBoxContainer2
@onready var _cool_down = $VBoxContainer/HBoxContainer2/CoolDown

func _on_gui_input(event:InputEvent):
	if event.is_action_pressed("left_mouse"):
		click_skill_slot.emit(current_skill)

func _on_mouse_entered():
	update_skill_detail.emit(current_skill,true)

func _on_mouse_exited():
	update_skill_detail.emit(current_skill,false)

func update(skill:BaseSkill):
	current_skill = skill
	if skill == null:
		_type.hide()
		h_box_container_2.hide()
		_label.text = "null"
		return
	if skill.type == skill.SkillType.PHYSICAL:
		_type.texture = SWORD
	else:
		_type.texture = WAND
	_label.text = skill.skill_name
	_speed_text.text = str(skill.speed)
	_cost_text.text = str(skill.cost)
	_cool_down.text = str(skill.cool_down)
