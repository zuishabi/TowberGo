extends Node2D

var player_map:Dictionary[int,Actor]

func _ready():
	pass

# 刷新玩家管理器
func refresh():
	for i in player_map:
		player_map[i].queue_free()
	player_map.clear()

func add_player(actor:Actor):
	player_map[actor.uid] = actor
	add_child(actor)

func remove_player(uid:int):
	if player_map[uid] != null:
		player_map[uid].queue_free()
		player_map.erase(uid)

func player_move(uid:int,from_pos:Vector2i,to_pos:Vector2i):
	if player_map[uid] == null:
		return
	var player:Actor = player_map[uid]
	player.move_towards(from_pos,to_pos)
