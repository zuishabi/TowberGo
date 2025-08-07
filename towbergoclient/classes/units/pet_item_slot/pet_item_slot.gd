class_name PetItemSlot
extends PanelContainer

@onready var _label = $Label
@onready var _texture_rect = $TextureRect
var current_item:BasePetItem
var current_pet_id:int


func update(item:BasePetItem,pet_id:int):
	current_item = item
	_label.text = str(item.pet_item_count)
	_texture_rect.texture = item.pet_item_texture
	current_pet_id = pet_id


func _on_mouse_entered():
	GameManager.show_pet_item_detail.emit(current_item)


func _on_mouse_exited():
	GameManager.hide_item_detail.emit()


func _on_gui_input(event:InputEvent):
	if event.is_action_pressed("left_mouse"):
		GameManager.show_use_pet_item.emit(current_item,current_pet_id)
