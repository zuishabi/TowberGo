extends Node

var loaded:bool = false
var item_bag:Dictionary[int,BaseItem]
var pet_item_bag:Dictionary[int,BasePetItem]
var id:int
var username:String
var can_move:bool = true

func delete_item(id:int,count:int):
	item_bag[id].item_count -= count
	if item_bag[id].item_count <= 0:
		item_bag.erase(id)

func add_item(id:int,count:int):
	if item_bag.has(id):
		item_bag[id].item_count += count
	else:
		item_bag[id] = ItemManager.generate_items(id,count)

func delete_pet_item(id:int,count:int):
	pet_item_bag[id].pet_item_count -= count
	if pet_item_bag[id].pet_item_count <= 0:
		pet_item_bag.erase(id)

func add_pet_item(id:int,count:int):
	if pet_item_bag.has(id):
		pet_item_bag[id].pet_item_count += count
	else:
		pet_item_bag[id] = ItemManager.generate_pet_item(id,count)
