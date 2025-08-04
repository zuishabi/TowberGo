extends Node

var loaded:bool = false
var item_bag:Dictionary[int,BaseItem]

func delete_item(id:int,count:int):
	item_bag[id].item_count -= count
	if item_bag[id].item_count <= 0:
		item_bag.erase(id)

func add_item(id:int,count:int):
	if item_bag.has(id):
		item_bag[id].item_count += count
	else:
		item_bag[id] = ItemManager.generate_items(id,count)
