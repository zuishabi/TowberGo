class_name MailUnit
extends PanelContainer

var _content:String
var _sender:String
var _title:String
var _items:Array[BaseItem]
var mail_id:int

@onready var _sender_text = $VBoxContainer/Sender
@onready var _title_text = $VBoxContainer/Title

signal show_mail(mail:MailUnit)

func update(title:String,content:String,sender:String,items:Array[BaseItem],id:int):
	self._items = items
	self._content = content
	self._sender = sender
	self._title = title
	_title_text.text = content
	_sender_text.text = sender
	mail_id = id
	print(mail_id)

func _on_gui_input(event:InputEvent):
	if event.is_action_pressed("left_mouse"):
		show_mail.emit(self)
