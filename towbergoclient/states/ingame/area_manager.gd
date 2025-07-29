class_name AreaManager
extends Node2D


const AREA_MAP :Dictionary[String,String] = {
	"InitialVillage":"res://areas/initial_village/initial_village.tscn",
	"AdventureHub":"res://areas/adventure_hub/adventure_hub.tscn"
}

@onready var player_manager = $"../PlayerManager"
var current_area:Area

func _ready():
	pass

func set_current_area(area:String):
	for i in get_children():
		i.queue_free()
	var new_scene:Area = load(AREA_MAP[area]).instantiate()
	new_scene.area_manager = self
	player_manager.refresh()
	add_child(new_scene)
	current_area = new_scene
