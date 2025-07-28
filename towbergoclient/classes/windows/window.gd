class_name PopWindow
extends Window

@onready var _confirm = $PanelContainer/VBoxContainer/HBoxContainer/Confirm
@onready var _cancel = $PanelContainer/VBoxContainer/HBoxContainer/Cancel
@onready var _text = $PanelContainer/VBoxContainer/Text

var _confirm_callable:Callable
var _cancel_callable:Callable

func _ready():
	self.hide()

func show_confirm(text:String,confirm_callable:Callable = _default_callable):
	self.show()
	_confirm.show()
	_cancel.hide()
	_text.text = text
	_confirm_callable = confirm_callable

func show_choose(text:String,confirm_callable:Callable = _default_callable,cancel_callable:Callable = _default_callable):
	self.show()
	_confirm.show()
	_cancel.show()
	_text.text = text
	_confirm_callable = confirm_callable
	_cancel_callable = cancel_callable

func _default_callable():
	pass

func _on_confirm_pressed():
	self.hide()
	_confirm_callable.call()

func _on_cancel_pressed():
	self.hide()
	_cancel_callable.call()
