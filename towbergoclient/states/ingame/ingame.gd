extends Node2D

const packets := preload("res://packets.gd")
const ACTOR = preload("res://classes/actor/actor.tscn")
const GET_WINDOW = preload("res://classes/units/get_window/get_window.tscn")

@onready var _window = $Window
@onready var _player_manager = $PlayerManager
@onready var _area_manager = $AreaManager
@onready var _chat_box = $UI/ChatBox
@onready var _mail_window = $UI/Mail
@onready var _bag_window = $UI/Bag
@onready var _ui = $UI
@onready var _pet_bag = $UI/PetBag


func _ready():
	GameManager.show_choose.connect(_window.show_choose)
	GameManager.show_confirm.connect(_window.show_confirm)
	WS.packet_received.connect(_on_ws_packted_received)
	WS.connection_closed.connect(_on_connection_closed)
	var packet := packets.Packet.new()
	var enter_request := packet.new_player_enter_request()
	enter_request.set_area_name("InitialVillage")
	enter_request.set_entrance_id(0)
	WS.send(packet)
	# 请求获得背包物品
	var get_bag := packets.Packet.new()
	get_bag.new_bag_request()
	WS.send(get_bag)
	# 请求获得宠物背包物品
	var get_pet_bag := packets.Packet.new()
	get_pet_bag.new_pet_item_bag_request()
	WS.send(get_pet_bag)


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
	elif msg.has_player_enter_area_response():
		_handle_player_enter_area_response(msg.get_player_enter_area_response())
	elif msg.has_mail():
		_handle_mail(msg.get_mail())
	elif msg.has_mail_collect_response():
		_handle_mail_collect_response(msg.get_mail_collect_response())
	elif msg.has_deny_response():
		_handle_deny_response(msg.get_deny_response().get_reason())
	elif msg.has_bag():
		_handle_bag_message(msg.get_bag())
	elif msg.has_use_bag_item_response():
		_handle_use_bag_response(msg.get_use_bag_item_response().get_success(),msg.get_use_bag_item_response().get_reason())
	elif msg.has_ui_packet():
		_handle_ui_message(msg.get_ui_packet())
	elif msg.has_add_bag_item():
		PlayerManager.add_item(msg.get_add_bag_item().get_id(),msg.get_add_bag_item().get_count())
		_bag_window.update()
		if !msg.get_add_bag_item().get_compensate():
			var new_get_window := GET_WINDOW.instantiate()
			_ui.add_child(new_get_window)
			new_get_window.add_item(msg.get_add_bag_item().get_id(),msg.get_add_bag_item().get_count())
	elif msg.has_delete_bag_item():
		PlayerManager.delete_item(msg.get_delete_bag_item().get_id(),msg.get_delete_bag_item().get_count())
		_bag_window.update()
	elif msg.has_get_pet():
		print("get pet ",msg.get_get_pet().get_id())
	elif msg.has_pet_bag_response():
		print("get pet bag ",msg.get_pet_bag_response())
		_handle_get_pet_bag_response(msg.get_pet_bag_response())
	elif msg.has_learn_skill_response():
		_handle_learn_skill_response(msg.get_learn_skill_response())
	elif msg.has_pet_item_bag_response():
		var m := msg.get_pet_item_bag_response()
		for i:int in m.get_id().size():
			PlayerManager.pet_item_bag[m.get_id()[i]] = ItemManager.generate_pet_item(m.get_id()[i],m.get_count()[i])
	elif msg.has_add_pet_item():
		var i := msg.get_add_pet_item()
		PlayerManager.add_pet_item(i.get_id(),i.get_count())
		if !i.get_compensate():
			var new_get_window := GET_WINDOW.instantiate()
			_ui.add_child(new_get_window)
			new_get_window.add_pet_item(i.get_id(),i.get_count())
	elif msg.has_delete_pet_item():
		var i := msg.get_delete_pet_item()
		PlayerManager.delete_pet_item(i.get_id(),i.get_count())
	elif msg.has_use_pet_item_response():
		var m := msg.get_use_pet_item_response()
		_handle_use_pet_item_response(m.get_success(),m.get_reason())
	elif msg.has_equipped_pet_info_response():
		var m := msg.get_equipped_pet_info_response()
		var pet := PetManager.msg_to_pet(m.get_pet())
		GameManager.update_equipped_pet_info.emit(pet,m.get_id())


func _handle_player_enter(sender_id:int,msg:packets.PlayerEnterAreaMessage):
	var new_actor:Actor = ACTOR.instantiate()
	new_actor.uid = sender_id
	new_actor.is_self = sender_id == 0
	new_actor.global_position = Vector2(msg.get_x(),msg.get_y())
	new_actor._target_pos = new_actor.global_position
	_player_manager.add_player(new_actor)
	if new_actor.is_self:
		new_actor.set_camera_limit(_area_manager.current_area.limit)


func _handle_player_movement(sender_id:int,msg:packets.PlayerMoveMessage):
	_player_manager.player_move(sender_id,Vector2(msg.get_from_x(),msg.get_from_y()),Vector2(msg.get_to_x(),msg.get_to_y()))


func _handle_player_leave(sender_id:int,msg:packets.PlayerLeaveAreaMessage):
	_player_manager.remove_player(sender_id)


func _handle_chat(sender_id:int,msg:packets.ChatMessage):
	_chat_box.add_chat(msg.get_username(),msg.get_content(),msg.get_type())


func _handle_player_enter_area_response(msg:packets.PlayerEnterAreaResponseMessage):
	if msg.get_success():
		_area_manager.set_current_area(msg.get_area_name())
	else:
		print(msg.get_reason())


func _handle_mail(msg:packets.MailMessage):
	var items:Array[BaseItem]
	for i in msg.get_items():
		items.append(ItemManager.generate_items(i.get_id(),i.get_count()))
	var pet_items:Array[BasePetItem]
	for i in msg.get_pet_items():
		pet_items.append(ItemManager.generate_pet_item(i.get_id(),i.get_count()))
	_mail_window.add_mail(msg.get_titles(),msg.get_contents(),msg.get_sender(),items,pet_items,msg.get_id())


func _handle_mail_collect_response(msg:packets.MailCollectResponseMessage):
	if !msg.get_success():
		_window.show_confirm(msg.get_reason())
	else:
		_mail_window.delete_mail(msg.get_id())


func _handle_deny_response(reason:String):
	_window.show_confirm(reason)


func _handle_bag_message(msg:packets.BagMessage):
	for i:int in msg.get_id().size():
		PlayerManager.item_bag[msg.get_id()[i]] = ItemManager.generate_items(msg.get_id()[i],msg.get_count()[i])
	_bag_window.update()


func _handle_use_bag_response(success:bool,reason:String):
	if !success:
		_window.show_confirm(reason)
	else:
		GameManager.use_item_success.emit()


func _handle_use_pet_item_response(success:bool,reason:String):
	if !success:
		_window.show_confirm(reason)
	else:
		GameManager.use_pet_item_success.emit()

func _handle_ui_message(msg:packets.UiPacket):
	if msg.has_open_ui():
		_handle_open_ui(msg.get_open_ui().get_path())


func _handle_open_ui(path:String):
	var ui:PackedScene = load("res://classes/units/ui/"+path+"/"+path+".tscn")
	var object := ui.instantiate()
	_ui.add_child(object)


func _handle_get_pet_bag_response(msg:packets.PetBagResponseMessage):
	var pets:Array[BasePet]
	pets.resize(5)
	for i in msg.get_pet().size():
		if msg.get_pet()[i].get_pet_id() == 0:
			pets[i] = null
		else:
			pets[i] = PetManager.msg_to_pet(msg.get_pet()[i])
	_pet_bag.update(pets)


func _handle_learn_skill_response(msg:packets.LearnSkillResponseMessage):
	if msg.get_success():
		_window.show_confirm("learn skill success")
	else:
		_window.show_confirm("learn skill error: " + msg.get_reason())
