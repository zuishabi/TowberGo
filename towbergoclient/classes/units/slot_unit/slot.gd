class_name Slot
extends PanelContainer

@onready var texture_rect = $TextureRect
@onready var count = $Count

var current_item:BaseItem

func update(item:BaseItem):
	current_item = item
	texture_rect.texture = current_item.item_texture
	count.text = str(item.item_count)

func _on_gui_input(event:InputEvent):
	if event.is_action_pressed("left_mouse"):
		ItemManager.show_item_detail.emit(current_item)
