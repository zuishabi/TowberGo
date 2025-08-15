extends TextureProgressBar

var tween:Tween

func update_value(mana:int):
	if tween == null || !tween.is_valid():
		tween = create_tween()
	if tween.is_running():
		tween.kill()
		tween = create_tween()
	tween.set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self,"value",mana,0.2)
