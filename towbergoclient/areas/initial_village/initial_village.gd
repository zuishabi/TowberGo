extends Area

const packets := preload("res://packets.gd")

func _on_adventure_hub_entrance_body_entered(body):
	if body is Actor:
		if body.is_self:
			area_manager.set_current_area(area_manager.AREA.ADVENTURE_HUB)
			var packet := packets.Packet.new()
			var enter_request := packet.new_player_enter_request()
			enter_request.set_area_name("AdventureHub")
			enter_request.set_entrance_id(0)
			WS.send(packet)
