extends Window

@onready var _texture_rect = $PanelContainer/VBoxContainer/HBoxContainer/TextureRect
@onready var _item_name = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/ItemName
@onready var _spin_box = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/SpinBox

var current_item:BaseItem
var current_pet_item:BasePetItem
var pet_id:int

func _ready():
	GameManager.show_use_item.connect(update_item)
	GameManager.show_use_pet_item.connect(update_pet_item)
	self.hide()


func update_item(item:BaseItem):
	self.show()
	current_item = item
	current_pet_item = null
	_texture_rect.texture = current_item.item_texture
	_item_name.text = current_item.item_name
	_spin_box.max_value = current_item.item_count


func update_pet_item(item:BasePetItem,pet:int):
	self.show()
	current_item = null
	current_pet_item = item
	pet_id = pet
	_texture_rect.texture = current_pet_item.pet_item_texture
	_item_name.text = current_pet_item.pet_item_name
	_spin_box.max_value = current_pet_item.pet_item_count


func _on_confirm_pressed():
	var packet := GameManager.packets.Packet.new()
	if current_item != null:
		var use_item := packet.new_use_bag_item_request()
		use_item.set_id(current_item.item_id)
		use_item.set_count(_spin_box.value)
		WS.send(packet)
	elif current_pet_item != null:
		var use_pet_item := packet.new_use_pet_item_request()
		use_pet_item.set_pet_id(pet_id)
		use_pet_item.set_count(_spin_box.value)
		use_pet_item.set_id(current_pet_item.pet_item_id)
		WS.send(packet)
		# 请求更新宠物状态
		var update_pet_info_req := GameManager.packets.Packet.new()
		var t := update_pet_info_req.new_equipped_pet_info_request()
		t.set_id(pet_id)
		WS.send(update_pet_info_req)
	self.hide()


func _on_cancel_pressed():
	self.hide()
