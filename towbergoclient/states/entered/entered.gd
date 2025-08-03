extends Node

const packets := preload("res://packets.gd")

@onready var _log:Log = $UI/Log
@onready var _main = $UI/Main
@onready var _window = $UI/Window
const MY_TRUSTED_CAS = preload("res://my_trusted_cas.crt")

var ok_callable:Callable

func _ready():
	_main.hide()
	_log.show()
	_window.hide()
	WS.connected_to_server.connect(_on_ws_connected_to_server)
	WS.connection_closed.connect(_on_connection_closed)
	WS.packet_received.connect(_on_ws_packted_received)
	if WS.connect_to_url("ws://127.0.0.1:8880/ws",null) != OK:
		_log.error("can not connect to the server...")
	else:
		_log.success("connecting to the server...")

func _on_ws_connected_to_server():
	_log.success("connect the server success")
	_log.hide()
	_main.show()
	_main.init()

func _on_connection_closed():
	_log.error("the connection has closed")
	_window.show_confirm("connection closed")

func _on_ws_packted_received(msg:packets.Packet):
	if msg.has_ok_response():
		_window.show_confirm("register success")
		ok_callable.call()
	elif msg.has_deny_response():
		_window.show_confirm(msg.get_deny_response().get_reason())
	elif msg.has_login_success():
		GameManager.id = msg.get_login_success().get_uid()
		GameManager.username = msg.get_login_success().get_username()
		GameManager.set_state(GameManager.State.INGAME)

func set_ok_callable(callable:Callable):
	ok_callable = callable
