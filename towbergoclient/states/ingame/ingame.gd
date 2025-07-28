extends Node2D

const packets := preload("res://packets.gd")
const ACTOR = preload("res://classes/actor/actor.tscn")

@onready var _window = $Window
@onready var _player_manager = $PlayerManager
@onready var _area_manager = $AreaManager
@onready var _chat_box = $UI/ChatBox

func _ready():
	WS.packet_received.connect(_on_ws_packted_received)
	WS.connection_closed.connect(_on_connection_closed)
	var packet := packets.Packet.new()
	var enter_request := packet.new_player_enter_request()
	enter_request.set_area_name("InitialVillage")
	enter_request.set_entrance_id(0)
	WS.send(packet)
	_area_manager.set_current_area(_area_manager.AREA.INITIAL_VILLAGE)

func _on_connection_closed():
	_window.show_confirm("connection closed")

func _on_ws_packted_received(msg:packets.Packet):
	if msg.has_player_enter():
		_handle_player_enter(msg.get_uid(),msg.get_player_enter())
	elif msg.has_player_movement():
		_handle_player_movement(msg.get_uid(),msg.get_player_movement())
	elif msg.has_player_leave():
		_handle_player_leave(msg.get_uid(),msg.get_player_leave())
	elif msg.has_chat():
		_handle_chat(msg.get_uid(),msg.get_chat())

func _handle_player_enter(sender_id:int,msg:packets.PlayerEnterAreaMessage):
	var new_actor:Actor = ACTOR.instantiate()
	new_actor.uid = sender_id
	new_actor.is_self = sender_id == 0
	new_actor.global_position = Vector2(msg.get_x(),msg.get_y())
	new_actor._target_pos = new_actor.global_position
	_player_manager.add_player(new_actor)

func _handle_player_movement(sender_id:int,msg:packets.PlayerMoveMessage):
	_player_manager.player_move(sender_id,Vector2(msg.get_from_x(),msg.get_from_y()),Vector2(msg.get_to_x(),msg.get_to_y()))

func _handle_player_leave(sender_id:int,msg:packets.PlayerLeaveAreaMessage):
	_player_manager.remove_player(sender_id)

func _handle_chat(sender_id:int,msg:packets.ChatMessage):
	_chat_box.add_chat(msg.get_username(),msg.get_content(),msg.get_type())
