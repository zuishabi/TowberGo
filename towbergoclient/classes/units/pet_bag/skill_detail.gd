extends PanelContainer

@onready var timer = $Timer
@onready var _name_text = $VBoxContainer/HBoxContainer/Name
@onready var _type = $VBoxContainer/HBoxContainer/Type
@onready var _cost_label = $VBoxContainer/Stats1/Cost/Label
@onready var _cooldown_label = $VBoxContainer/Stats1/CoolDown/Label
@onready var _speed_label = $VBoxContainer/Stats1/Speed/Label
@onready var _description = $VBoxContainer/description

const SWORD = preload("res://assets/items/sword.tres")
const WAND = preload("res://assets/items/wand.tres")

func _ready():
	self.hide()

func update(skill:BaseSkill):
	if skill == null:
		return
	timer.stop()
	self.show()
	if skill.type == skill.SkillType.PHYSICAL:
		_type.texture = SWORD
	else:
		_type.texture = WAND
	_name_text.text = skill.skill_name
	_description.text = skill.description
	_cost_label.text = str(skill.cost)
	_cooldown_label.text = str(skill.cool_down)
	_speed_label.text = str(skill.speed)

func update_hide():
	timer.start()

func _process(delta):
	self.global_position = get_global_mouse_position()

func _on_timer_timeout():
	self.hide()
