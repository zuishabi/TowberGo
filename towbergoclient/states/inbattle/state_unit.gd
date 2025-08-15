extends PanelContainer

@onready var _h_box_container = $HBoxContainer
@onready var _texture_rect = $HBoxContainer/TextureRect
@onready var _name_text = $HBoxContainer/VBoxContainer/Name
@onready var _hp = $HBoxContainer/VBoxContainer/Hp
@onready var _mana = $HBoxContainer/VBoxContainer/Mana
@onready var _hp_text = $HBoxContainer/VBoxContainer/Hp/HpText
@onready var _mana_text = $HBoxContainer/VBoxContainer/Mana/ManaText

@export var mirror:bool


func _ready():
	if mirror:
		_h_box_container.move_child(_texture_rect,1)
		_name_text.horizontal_alignment = 2
		_texture_rect.flip_h = true

func update_pet(pet:BattleManager.BattlePet):
	_texture_rect.texture = pet.pet.pet_texture
	_name_text.text = pet.pet.pet_name + " lv." + str(pet.pet.level)
	_hp.max_value = pet.pet.max_hp
	_hp.update_value(pet.pet.hp)
	_mana.max_value = pet.pet.max_mana
	_mana.update_value(pet.pet.mana)
