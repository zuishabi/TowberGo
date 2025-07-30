extends Window

const MAIL_UNIT = preload("res://classes/units/mail_unit/mail_unit.tscn")
const packets := preload("res://packets.gd")
@onready var _content = $HBoxContainer/ContentScroll/Content
@onready var _list = $HBoxContainer/ListScroll/List

var current_mail:MailUnit

func _ready():
	self.hide()

func show_window():
	self.show()
	_content.refresh()
	_content.hide()
	for i in _list.get_children():
		i.queue_free()
	var packet := packets.Packet.new()
	packet.new_mail_request()
	WS.send(packet)

func add_mail(title:String,content:String,sender:String,items:Array[BaseItem],id:int):
	var new_mail:MailUnit = MAIL_UNIT.instantiate()
	_list.add_child(new_mail)
	new_mail.update(title,content,sender,items,id)
	new_mail.show_mail.connect(show_mail)

func delete_mail(mail_id:int):
	for i:MailUnit in _list.get_children():
		if i.mail_id == mail_id:
			i.queue_free()
			return

func show_mail(mail:MailUnit):
	current_mail = mail
	_content.update(mail)
	_content.show()

func _on_close_requested():
	self.hide()
