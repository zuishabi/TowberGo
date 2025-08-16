extends Window

func _on_close_requested():
	self.queue_free()


func _on_button_pressed():
	var msg := GameManager.packets.Packet.new()
	msg.new_npc_interact().new_heal()
	WS.send(msg)
	self.queue_free()
