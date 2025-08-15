extends Node

class BattlePlayer:
	var player_name:String
	var pets:Array[BattlePet]
	var current_pet:BattlePet

class BattlePet:
	var pet:BasePet
	var buffs:Array[int]

class AttackStats:
	var number:int
	var skill_id:int
	var buffs:Array[int]
	var physical_damage:int
	var magic_damage:int
	var pet_stats:Array[PetManager.Stats]


var players:Array[BattlePlayer]
var number:int
const packets := preload("res://packets.gd")

signal update_player_information(player:BattlePlayer)

func _ready():
	players.resize(2)


func refresh(number:int):
	players.clear()
	players.resize(2)
	self.number = number


func sync_player(number:int,player_name:String,pets:Array[BasePet]):
	players[number] = BattlePlayer.new()
	players[number].player_name = player_name
	players[number].pets.resize(5)
	for i in pets.size():
		players[number].pets[i] = BattlePet.new()
		players[number].pets[i].pet = pets[i]
	players[number].current_pet = players[number].pets[0]

func get_the_other()->int:
	if number == 0:
		return 1
	return 0

func msg_to_attack_stats(msg:packets.AttackStatsMessage)->AttackStats:
	var res:AttackStats = AttackStats.new()
	res.magic_damage = msg.get_magic_damage()
	res.physical_damage = msg.get_physical_damage()
	res.number = msg.get_number()
	res.skill_id = msg.get_skill_id()
	res.pet_stats = [PetManager.msg_to_stats(msg.get_pet_stats()[0]),PetManager.msg_to_stats(msg.get_pet_stats()[1])]
	return res
