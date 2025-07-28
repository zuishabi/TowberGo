class_name AreaManager
extends Node2D

enum AREA{
	INITIAL_VILLAGE,
	ADVENTURE_HUB,
}

const AREA_MAP :Dictionary[AREA,String] = {
	AREA.INITIAL_VILLAGE:"res://areas/initial_village/initial_village.tscn",
	AREA.ADVENTURE_HUB:"res://areas/adventure_hub/adventure_hub.tscn"
}

@onready var player_manager = $"../PlayerManager"

func _ready():
	pass

func set_current_area(area:AREA):
	for i in get_children():
		i.queue_free()
	var new_scene:Area = load(AREA_MAP[area]).instantiate()
	new_scene.area_manager = self
	player_manager.refresh()
	add_child(new_scene)
