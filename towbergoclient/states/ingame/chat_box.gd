extends PanelContainer

const packets := preload("res://packets.gd")
const CHAT_UNIT = preload("res://classes/units/chat_unit/chat_unit.tscn")
var current_type:int = 0

@onready var _contents = $VBoxContainer/ContentsContainer/ScrollContainer/VBoxContainer
@onready var _tab_bar = $VBoxContainer/TabBar
@onready var _line_edit = $VBoxContainer/LineEdit
@onready var _contents_container = $VBoxContainer/ContentsContainer


func _ready():
	_tab_bar.hide()
	_line_edit.hide()
	_contents_container.hide()

func _on_line_edit_text_submitted(new_text:String):
	var packet := packets.Packet.new()
	var chat := packet.new_chat()
	chat.set_type(current_type)
	chat.set_content(new_text)
	chat.set_username(GameManager.username)
	WS.send(packet)
	_line_edit.text = ""

func _on_tab_bar_tab_changed(tab:int):
	current_type = tab
	for i in _contents.get_children():
		i.queue_free()

func add_chat(user_name:String,content:String,type:int):
	if type == current_type:
		var new_chat:ChatUnit = CHAT_UNIT.instantiate()
		_contents.add_child(new_chat)
		new_chat.update(user_name,content)

func _on_close_pressed():
	_contents_container.visible = !_contents_container.visible
	_line_edit.visible = !_line_edit.visible
	_tab_bar.visible = !_tab_bar.visible
