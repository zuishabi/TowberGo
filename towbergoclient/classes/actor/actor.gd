class_name Actor
extends CharacterBody2D

const packets := preload("res://packets.gd")

var is_self:bool
var uid:int
var _target_pos:Vector2

@onready var _move_ray = $MoveRay
@onready var _body = $Sprites/Body
@onready var _camera_2d:Camera2D = $Camera2D

func _ready():
	if uid == 0:
		_camera_2d.enabled = true

func move_towards(from:Vector2,to:Vector2):
	self.global_position = from
	_target_pos = to

func _process(delta):
	if abs(global_position.x - _target_pos.x) < 1 && abs(global_position.y - _target_pos.y) < 1:
		velocity = Vector2.ZERO
		_body.play("stand")
	else:
		var direction:Vector2 = global_position.direction_to(_target_pos)
		velocity = direction * 100
		_body.play("walk")
	move_and_slide()

func _unhandled_input(event:InputEvent):
	if GameManager.can_move && is_self && event.is_action_pressed("left_mouse"):
		var target:Vector2 = get_global_mouse_position()
		_move_ray.target_position = to_local(target)
		_move_ray.force_raycast_update()
		# 检查是否有碰撞
		if _move_ray.get_collider() != null:
			target = _move_ray.get_collision_point()
		
		var packet := packets.Packet.new()
		var movement := packet.new_player_movement()
		movement.set_from_x(global_position.x)
		movement.set_from_y(global_position.y)
		movement.set_to_x(target.x)
		movement.set_to_y(target.y)
		WS.send(packet)
		_target_pos = target

func set_camera_limit(limit:Vector2i):
	_camera_2d.limit_bottom = limit.y
	_camera_2d.limit_right = limit.x
