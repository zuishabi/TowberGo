extends Window

const packets := preload("res://packets.gd")

func _on_close_pressed():
	self.queue_free()

func _on_confirm_pressed():
	var packet := packets.Packet.new()
	var request := packet.new_ui_packet().new_initial_pet_request()
	request.set_request_id(1)
	WS.send(packet)
	self.queue_free()
