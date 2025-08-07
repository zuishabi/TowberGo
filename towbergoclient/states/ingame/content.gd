extends VBoxContainer

@onready var _title = $Title
@onready var _main_content = $MainContent
@onready var _item_list = $ItemList
@onready var _collect = $Buttons/Collect
@onready var _delete = $Buttons/Delete

const packets := preload("res://packets.gd")

var current_mail:MailUnit

func refresh():
	pass

func update(mail:MailUnit):
	current_mail = mail
	_title.text = mail._title
	_main_content.text = mail._content
	_item_list.clear()
	if mail._items.size() != 0:
		_item_list.show()
		_collect.show()
		_delete.hide()
		for i:BaseItem in mail._items:
			_item_list.add_item(i.item_name + str(i.item_count),i.item_texture,false)
		for i:BasePetItem in mail._pet_items:
			_item_list.add_item(i.pet_item_name + str(i.pet_item_count),i.pet_item_texture,false)
	else:
		_collect.hide()
		_delete.show()
		_item_list.hide()

func _on_delete_pressed():
	var packet := packets.Packet.new()
	var delete := packet.new_mail_delete()
	delete.set_id(current_mail.mail_id)
	WS.send(packet)
	current_mail.queue_free()
	current_mail = null
	self.hide()

func _on_collect_pressed():
	var packet := packets.Packet.new()
	var collect := packet.new_mail_collect()
	collect.set_id(current_mail.mail_id)
	WS.send(packet)
	self.hide()
