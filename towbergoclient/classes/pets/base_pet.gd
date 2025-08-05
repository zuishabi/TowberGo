class_name BasePet
extends Resource

@export var pet_id:int
@export var pet_name:String
@export var pet_texture:Texture2D
var id:int
var level:int
var exp:int
var max_hp:int
var hp:int
var max_mana:int
var mana:int
var strength:int
var intelligence:int
var speed:int
var defense:int
var skills:Array[BaseSkill]
