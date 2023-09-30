extends Node2D
class_name Platform

var _direction: int = 0

var _rotating_towards: int = 0
var _rotating_timer: float = 0.0
var _rotation_step: int = -1

var _step: int = 0

@onready var handle: Sprite2D = $Handle

const PI2 = PI * 2
const HALF_PI = PI / 2

func _ready():
	pass


func _process(delta):
	if _direction != _rotating_towards:
		var angle_from = _direction * HALF_PI
		var angle_to = _rotating_towards * HALF_PI

		if _direction == 3 and _rotating_towards == 0:
			angle_to += PI2
		elif _direction == 0 and _rotating_towards == 3:
			angle_from += PI2

		handle.rotation = lerpf(angle_from, angle_to, _rotating_timer)
		_rotating_timer += delta

		if _rotating_timer >= 1.0:
			_complete_rotation()


func on_enter_cell(_cell: Conveyor):
	pass


func on_exit_cell(_cell: Conveyor):
	_step += 1
	_complete_rotation()
	pass


func rotate_right():
	if _rotation_step == _step:
		return
	_rotation_step = _step
	_rotating_towards = (_direction + 1) % 4


func rotate_left():
	if _rotation_step == _step:
		return
	_rotation_step = _step
	_rotating_towards = (4 + _direction - 1) % 4


func _complete_rotation():
	_direction = _rotating_towards
	handle.rotation = _direction * HALF_PI
	_rotating_timer = 0.0
