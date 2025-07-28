class_name ChatUnit
extends PanelContainer

@onready var _rich_text_label = $RichTextLabel

func update(user_name:String,content:String):
	_rich_text_label.text = "[b]" + user_name + "[/b]: " + content
