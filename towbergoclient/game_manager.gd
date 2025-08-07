extends Node

enum State{
	ENTERED,
	INGAME,
}

var _states_scenes:Dictionary[State,String] = {
	State.ENTERED: "res://states/entered/entered.tscn",
	State.INGAME: "res://states/ingame/ingame.tscn",
}

signal show_confirm(text:String,callable:Callable)
signal show_choose(text:String,confirm:Callable,cancel:Callable)
signal show_pet_bag_detail(pet:BasePet)
signal show_item_detail(item:BaseItem)
signal show_pet_item_detail(item:BasePetItem)
signal hide_item_detail
signal show_use_item(item:BaseItem)
signal show_use_pet_item(item:BasePetItem,pet:int)
signal use_pet_item_success
signal use_item_success
signal update_equipped_pet_info(pet:BasePet,id:int)

var id:int
var username:String
var _current_scene_root:Node
var can_move:bool = true
const packets := preload("res://packets.gd")

func set_state(state:State):
	if _current_scene_root != null:
		_current_scene_root.queue_free()

	var scene:PackedScene = load(_states_scenes[state])
	_current_scene_root = scene.instantiate()
	add_child(_current_scene_root)
