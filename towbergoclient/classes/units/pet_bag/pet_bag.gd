extends Window

@onready var _h_box_container = $NinePatchRect/MarginContainer/VBoxContainer/PetList/HBoxContainer
@onready var _detail = $NinePatchRect/MarginContainer/VBoxContainer/Detail/HBoxContainer
@onready var _pet_name = $NinePatchRect/MarginContainer/VBoxContainer/Detail/HBoxContainer/LeftPanel/Left/PetName
@onready var _texture_rect = $NinePatchRect/MarginContainer/VBoxContainer/Detail/HBoxContainer/LeftPanel/Left/TextureRect
@onready var _lv = $NinePatchRect/MarginContainer/VBoxContainer/Detail/HBoxContainer/LeftPanel/Left/Level/Lv
@onready var _exp_progress = $NinePatchRect/MarginContainer/VBoxContainer/Detail/HBoxContainer/LeftPanel/Left/Level/ExpProgress
@onready var _exp_text = $NinePatchRect/MarginContainer/VBoxContainer/Detail/HBoxContainer/LeftPanel/Left/Level/ExpProgress/ExpText
@onready var _hp = $NinePatchRect/MarginContainer/VBoxContainer/Detail/HBoxContainer/LeftPanel/Left/Hp
@onready var _hp_text = $NinePatchRect/MarginContainer/VBoxContainer/Detail/HBoxContainer/LeftPanel/Left/Hp/HpText
@onready var _mana = $NinePatchRect/MarginContainer/VBoxContainer/Detail/HBoxContainer/LeftPanel/Left/Mana
@onready var _mana_text = $NinePatchRect/MarginContainer/VBoxContainer/Detail/HBoxContainer/LeftPanel/Left/Mana/ManaText
@onready var _info_container = $NinePatchRect/MarginContainer/VBoxContainer/Detail/HBoxContainer/RightPanel/TabContainer/Info
@onready var _pet_item_container = $NinePatchRect/MarginContainer/VBoxContainer/Detail/HBoxContainer/RightPanel/TabContainer/PetItem

func _ready():
	self.hide()
	_info_container.show()
	_pet_item_container.hide()
	GameManager.show_pet_bag_detail.connect(_show_pet_detail)

func _on_texture_button_pressed():
	self.hide()
	_detail.hide()

func update(pets:Array[BasePet]):
	_detail.hide()
	for i in pets.size():
		var slot:PetBagSlot = _h_box_container.get_child(i)
		slot.update(pets[i])

func _show_pet_detail(pet:BasePet):
	if pet == null:
		return
	_detail.show()
	_pet_name.text = pet.pet_name
	_texture_rect.texture = pet.pet_texture
	_lv.text = "lv." + str(pet.level)
	_exp_progress.max_value = PetManager.ExpList[pet.level-1]
	_exp_progress.value = pet.exp - (PetManager.ExpList[pet.level-2] if (pet.level > 1)  else 0)
	_exp_text.text = str(_exp_progress.value) + "/" + str(_exp_progress.max_value)
	_hp.max_value = pet.max_hp
	_hp.value = pet.hp
	_hp_text.text = str(pet.hp) + "/" + str(pet.max_hp)
	_mana.max_value = pet.max_mana
	_mana.value = pet.mana
	_mana_text.text = str(pet.mana) + "/" + str(pet.max_mana)

func _on_tab_bar_tab_changed(tab:int):
	if tab == 0:
		_info_container.show()
		_pet_item_container.hide()
	else:
		_info_container.hide()
		_pet_item_container.show()
