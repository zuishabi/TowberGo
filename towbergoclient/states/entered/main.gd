extends VBoxContainer

@onready var _login = $MarginContainer/Login
@onready var _register = $MarginContainer/Register
@onready var _login_user_name = $MarginContainer/Login/UserName
@onready var _login_password = $MarginContainer/Login/Password
@onready var _window = $"../Window"
@onready var _register_user_name = $MarginContainer/Register/UserName
@onready var _register_password = $MarginContainer/Register/Password
@onready var _register_confirm_password = $MarginContainer/Register/ConfirmPassword
@onready var entered = $"../.."

const packets := preload("res://packets.gd")

func init():
	_login.show()
	_register.hide()

func _on_login_pressed():
	var user_name:String = _login_user_name.text
	user_name.replace(" ","")
	if user_name == "" || _login_password.text == "":
		_window.show_confirm("Please fill the information")
		return
	var packet := packets.Packet.new()
	var login_request := packet.new_login_request()
	login_request.set_username(user_name)
	login_request.set_password(_login_password.text)
	WS.send(packet)

func _on_register_prompt_meta_clicked(meta):
	if meta == "register":
		_login.hide()
		_register.show()

func _on_register_pressed():
	var user_name:String = _register_user_name.text
	user_name.replace(" ","")
	if user_name == "" || _register_password.text == "":
		_window.show_confirm("Please fill the information")
		return
	if _register_confirm_password.text != _register_password.text:
		_window.show_confirm("Password do not match")
		return
	var packet := packets.Packet.new()
	var register_msg := packet.new_register_request()
	register_msg.set_password(_register_password.text)
	register_msg.set_username(user_name)
	WS.send(packet)
	entered.set_ok_callable(_register_success)

func _on_back_pressed():
	_login.show()
	_register.hide()

func _register_success():
	_window.show_confirm("Register success")
