extends ScrollContainer

@onready var _pet_item = $MarginContainer/PetItem
const PET_ITEM_SLOT = preload("res://classes/units/pet_item_slot/pet_item_slot.tscn")
@onready var _pet_bag = $"../../../../../../../.."


func _ready():
	GameManager.use_pet_item_success.connect(update)


func update():
	for i in _pet_item.get_children():
		i.queue_free()
	for i in PlayerManager.pet_item_bag:
		var new_pet_item_slot:PetItemSlot = PET_ITEM_SLOT.instantiate()
		_pet_item.add_child(new_pet_item_slot)
		new_pet_item_slot.update(PlayerManager.pet_item_bag[i],_pet_bag.choosed_pet.id)
