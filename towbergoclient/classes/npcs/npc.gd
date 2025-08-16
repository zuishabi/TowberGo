class_name NPC
extends CharacterBody2D

var current_npc:BaseNPC
var can_interact:bool

@onready var body = $Sprites/Body
@onready var name_text = $Name
@onready var input_panel = $InputPanel

func _ready():
	body.texture = current_npc.npc_texture
	name_text.text = "npc:" + current_npc.npc_name

func load_npc(npc:BaseNPC):
	current_npc = npc

func _on_area_2d_body_entered(body):
	if body is Actor:
		if body.is_self:
			can_interact = true
			input_panel.mouse_filter = 0

func _on_area_2d_body_exited(body):
	if body is Actor:
		if body.is_self:
			can_interact = false
			input_panel.mouse_filter = 2

func _on_input_panel_gui_input(event:InputEvent):
	if event.is_action_pressed("left_mouse") && can_interact:
		var packet := GameManager.packets.Packet.new()
		packet.new_interact_npc_request().set_id(current_npc.npc_id)
		WS.send(packet)
