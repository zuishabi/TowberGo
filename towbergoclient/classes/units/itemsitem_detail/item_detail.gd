extends Window

@onready var _panel_container = $PanelContainer
@onready var _label = $PanelContainer/VBoxContainer/Label
@onready var _texture_rect = $PanelContainer/VBoxContainer/TextureRect
@onready var _rich_text_label = $PanelContainer/VBoxContainer/RichTextLabel

func _ready():
	GameManager.show_item_detail.connect(update_item)
	GameManager.show_pet_item_detail.connect(update_pet_item)
	GameManager.hide_item_detail.connect(func():
		self.hide()
	)
	self.hide()

func update_item(item:BaseItem):
	self.show()
	_label.text = item.item_name
	_texture_rect.texture = item.item_texture
	_rich_text_label.text = item.item_description
	fix.call_deferred()

func update_pet_item(item:BasePetItem):
	self.show()
	_label.text = item.pet_item_name
	_texture_rect.texture = item.pet_item_texture
	_rich_text_label.text = item.pet_item_description
	fix.call_deferred()

func fix():
	self.size = _panel_container.size

func _process(delta):
	self.position = get_tree().root.get_mouse_position() + Vector2.RIGHT*10 + Vector2.UP*10
