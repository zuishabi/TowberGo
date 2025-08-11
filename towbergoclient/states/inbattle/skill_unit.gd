class_name SkillUnit
extends PanelContainer

@export var pos:int
var current_skill:BaseSkill
var locked:bool = false
signal select_skill(pos:int)
@onready var _type = $VBoxContainer/HBoxContainer/Type
@onready var _label = $VBoxContainer/HBoxContainer/Label
@onready var _speed_text = $VBoxContainer/HBoxContainer2/SpeedText
@onready var _cost_text = $VBoxContainer/HBoxContainer2/CostText
const SWORD = preload("res://assets/items/sword.tres")
const WAND = preload("res://assets/items/wand.tres")

func update(skill:BaseSkill):
	current_skill = skill
	if skill.type == BaseSkill.SkillType.PHYSICAL:
		_type.texture = SWORD
	else:
		_type.texture = WAND
	_label.text = skill.skill_name
	_speed_text.text = str(skill.speed)
	_cost_text.text = str(skill.cost)


func lock():
	self.locked = true
	self.mouse_default_cursor_shape = Control.CURSOR_ARROW


func unlock():
	self.locked = false
	self.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _on_gui_input(event:InputEvent):
	if event.is_action_pressed("left_mouse") && !locked:
		select_skill.emit(pos)
