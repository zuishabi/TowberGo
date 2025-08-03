extends Window

const SLOT = preload("res://classes/units/slot_unit/slot.tscn")
const packets := preload("res://packets.gd")
@onready var _grid_container = $HBoxContainer/MarginContainer/ScrollContainer/GridContainer
@onready var _use = $HBoxContainer/Detail/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/Use
@onready var _item_name = $HBoxContainer/Detail/MarginContainer/ScrollContainer/VBoxContainer/ItemName
@onready var _texture_rect = $HBoxContainer/Detail/MarginContainer/ScrollContainer/VBoxContainer/TextureRect
@onready var _rich_text_label = $HBoxContainer/Detail/MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/RichTextLabel
@onready var _detail = $HBoxContainer/Detail/MarginContainer/ScrollContainer
@onready var _spin_box = $HBoxContainer/Detail/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/SpinBox

var current_item:BaseItem

func _ready():
	self.hide()
	ItemManager.show_item_detail.connect(_show_item_detail)

func update():
	for i in _grid_container.get_children():
		i.queue_free()
	for i:int in PlayerManager.item_bag:
		var new_slot:Slot = SLOT.instantiate()
		_grid_container.add_child(new_slot)
		new_slot.update(PlayerManager.item_bag[i])

func show_bag():
	self.show()
	_detail.hide()
	current_item = null

func _on_close_requested():
	self.hide()

func _show_item_detail(item:BaseItem):
	_detail.show()
	_item_name.text = item.item_name
	current_item = item
	_texture_rect.texture = item.item_texture
	_rich_text_label.text = item.item_description
	if item.can_use:
		_use.show()
		_spin_box.show()
		_spin_box.max_value = item.item_count
	else:
		_use.hide()
		_spin_box.hide()

func _on_use_pressed():
	if _spin_box.value > 0:
		GameManager.show_choose.emit("do you want to use " + str(int(_spin_box.value)) + " " + current_item.item_name + "?",confirm_func)

func confirm_func():
	var packet := packets.Packet.new()
	var use_bag := packet.new_use_bag_item_request()
	use_bag.set_id(current_item.item_id)
	use_bag.set_count(_spin_box.value)
	WS.send(packet)

func _input(event):
	if self.visible && event.is_action_pressed("esc") && self.has_focus():
		self.hide()
