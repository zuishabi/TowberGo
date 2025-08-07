extends Window

@onready var _texture_rect = $MarginContainer/VBoxContainer/TextureRect
@onready var _text = $MarginContainer/VBoxContainer/Text

func add_item(id:int,count:int):
	var item:BaseItem = ItemManager.item_dictionary[id]
	_text.text = str(count) + "* " +item.item_name + "are added to your bag"

func add_pet(id:int):
	pass

func add_pet_item(id:int,count:int):
	var item:BasePetItem = ItemManager.pet_item_dictionary[id]
	_text.text = str(count) + "* " +item.pet_item_name + "are added to your pet bag"

func _on_confirm_pressed():
	self.queue_free()
