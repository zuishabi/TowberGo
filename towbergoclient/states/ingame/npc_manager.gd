extends Node2D

const packets := preload("res://packets.gd")
const npc := preload("res://classes/npcs/npc.tscn")

var npc_list:Dictionary[int,BaseNPC] = {
	1:preload("res://classes/npcs/InitialVillageHead.tres"),
	2:preload("res://classes/npcs/IntitialVillageHealer.tres"),
}

func msg_to_npc(msg:packets.NPCInfoMessage)->NPC:
	var res:NPC = npc.instantiate()
	res.load_npc(npc_list[msg.get_id()])
	return res

func refresh():
	for i in self.get_children():
		i.queue_free()

func add_npc(npc:NPC,pos:Vector2):
	self.add_child(npc)
	npc.global_position = pos
