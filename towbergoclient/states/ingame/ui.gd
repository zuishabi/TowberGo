extends CanvasLayer

@onready var _mail_window = $Mail
@onready var _bag_window = $Bag
const packets := preload("res://packets.gd")

func _on_mail_pressed():
	if !_mail_window.visible:
		_mail_window.show_window()

func _on_bag_pressed():
	if _bag_window.visible:
		return
	if !PlayerManager.loaded:
		PlayerManager.loaded = true
		var packet := packets.Packet.new()
		packet.new_bag_request()
		WS.send(packet)
	_bag_window.show_bag()

func show_pop_up(scene:PackedScene):
	pass
