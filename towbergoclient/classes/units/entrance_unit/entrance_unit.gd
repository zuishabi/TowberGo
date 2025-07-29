extends Area2D

@export var target_name:String
@export var target_id:int
var area:Area

func _ready():
	area = get_parent()

func _on_body_entered(body):
	if body is Actor:
		if body.is_self:
			var packet := area.packets.Packet.new()
			var enter_request := packet.new_player_enter_request()
			enter_request.set_area_name(target_name)
			enter_request.set_entrance_id(target_id)
			WS.send(packet)
