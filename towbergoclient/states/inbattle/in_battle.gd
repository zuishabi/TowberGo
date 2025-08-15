extends Node2D

const packets := preload("res://packets.gd")
@onready var _window = $UI/Window
@onready var battle_panel = $UI/BattlePanel

func _ready():
	WS.packet_received.connect(_on_ws_packted_received)
	WS.connection_closed.connect(_on_connection_closed)
	GameManager.show_choose.connect(_window.show_choose)
	GameManager.show_confirm.connect(_window.show_confirm)


func _on_ws_packted_received(msg:packets.Packet):
	if msg.has_battle_packet():
		_process_battle_packet(msg.get_battle_packet())
	elif msg.has_sync_state():
		if msg.get_sync_state().get_state() == 1:
			GameManager.set_state(GameManager.State.ENTERED)
		elif msg.get_sync_state().get_state() == 2:
			GameManager.set_state(GameManager.State.INGAME)


func _process_battle_packet(msg:packets.BattlePacket):
	if msg.has_sync_battle_information():
		var info := msg.get_sync_battle_information()
		var pets:Array[BasePet]
		for i in info.get_pet_messages():
			pets.append(PetManager.msg_to_pet(i))
		BattleManager.sync_player(info.get_number(),info.get_player_name(),pets)
		battle_panel.update_pet(BattleManager.players[info.get_number()].pets[0],info.get_number())
	elif msg.has_start_next_round():
		battle_panel.unlock_skills()
		print("开启下一回合")
	elif msg.has_attack_stats():
		var attack_stats:BattleManager.AttackStats = BattleManager.msg_to_attack_stats(msg.get_attack_stats())
		battle_panel.attack_stats_array.append(attack_stats)
	elif msg.has_battle_end():
		print("战斗结束")
	elif msg.has_round_end():
		battle_panel.round_end = true
		battle_panel.process_attack_stats()


func _on_connection_closed():
	_window.show_confirm("connection closed")
