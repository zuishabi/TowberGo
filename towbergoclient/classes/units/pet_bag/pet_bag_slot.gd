class_name PetBagSlot
extends PanelContainer

@onready var margin_container = $MarginContainer
@onready var texture_rect = $MarginContainer/VBoxContainer/TextureRect
@onready var hp = $MarginContainer/VBoxContainer/Hp
@onready var mana = $MarginContainer/VBoxContainer/Mana
var current_pet:BasePet

func update(pet:BasePet):
	current_pet = null
	if pet == null:
		margin_container.hide()
		return
	else:
		margin_container.show()
		current_pet = pet
	texture_rect.texture = current_pet.pet_texture
	hp.max_value = pet.max_hp
	hp.value = pet.hp
	mana.max_value = pet.max_mana
	mana.value = pet.mana

func _on_gui_input(event:InputEvent):
	if event.is_action_pressed("left_mouse"):
		GameManager.show_pet_bag_detail.emit(current_pet)
