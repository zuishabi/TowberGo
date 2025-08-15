extends Node

var item_dictionary:Dictionary[int,BaseItem] = {
	1:preload("res://classes/items/InitialPet.tres").duplicate(true)
}

func generate_items(id:int,count:int)->BaseItem:
	var res:BaseItem = item_dictionary[id].duplicate(true)
	res.item_count = count
	return res

signal show_item_detail(item:BaseItem)

var pet_item_dictionary:Dictionary[int,BasePetItem] = {
	1:preload("res://classes/pet_items/orange_sugar.tres")
}

func generate_pet_item(id:int,count:int)->BasePetItem:
	var res:BasePetItem = pet_item_dictionary[id].duplicate(true)
	res.pet_item_count = count
	return res
