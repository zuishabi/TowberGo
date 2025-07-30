extends CanvasLayer

@onready var _mail_window = $Mail

func _on_mail_pressed():
	_mail_window.show_window()
