class_name MailUnit
extends PanelContainer

var _content:String
var _sender:String
var _title:String
var _items:Array[BaseItem]
var _pet_items:Array[BasePetItem]
var mail_id:int

@onready var _sender_text = $VBoxContainer/Sender
@onready var _title_text = $VBoxContainer/Title

signal show_mail(mail:MailUnit)

func update(title:String,content:String,sender:String,items:Array[BaseItem],pet_items:Array[BasePetItem],id:int):
	self._items = items
	self._pet_items = pet_items
	self._content = content
	self._sender = sender
	self._title = title
	_title_text.text = content
	_sender_text.text = sender
	mail_id = id

func _on_gui_input(event:InputEvent):
	if event.is_action_pressed("left_mouse"):
		show_mail.emit(self)
