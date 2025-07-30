extends Node

var item_dictionary:Dictionary[int,BaseItem] = {
	1:preload("res://classes/items/InitialPet.tres").duplicate(true)
}

func generate_items(id:int,count:int)->BaseItem:
	var res:BaseItem = item_dictionary[id].duplicate(true)
	res.item_count = count
	return res
