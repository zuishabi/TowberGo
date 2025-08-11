class_name BaseSkill
extends Resource

@export var skill_id:int
@export var skill_name:String
@export var cost:int
@export var speed:int
@export var description:String
@export var type:SkillType
enum SkillType {MAGIC,PHYSICAL}
