extends ScrollContainer

@onready var _skill_slot_1 = $Info/Skill1/SkillSlot
@onready var _skill_slot_2 = $Info/Skill1/SkillSlot2
@onready var _skill_slot_3 = $Info/Skill2/SkillSlot
@onready var _skill_slot_4 = $Info/Skill2/SkillSlot2
@onready var _strength_label = $Info/Stats1/Strength/Label
@onready var _intelligence_label = $Info/Stats1/Intelligence/Label
@onready var _speed_label = $Info/Stats1/Speed/Label
@onready var _defense_label = $Info/Stats1/Defense/Label

func _ready():
	GameManager.show_pet_bag_detail.connect(_show_pet_detail)

func update(pet:BasePet):
	# TODO 处理技能显示
	_strength_label.text = str(pet.strength)
	_intelligence_label.text = str(pet.intelligence)
	_speed_label.text = str(pet.speed)
	_defense_label.text = str(pet.defense)

func _show_pet_detail(pet:BasePet):
	update(pet)
