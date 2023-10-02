extends Node2D
class_name Platform

var color: Color = Color.WHITE

var _direction: int = 0
var _shift: Vector2i = Vector2i.ZERO

var _rotating_towards: int = 0
var _rotating_timer: float = 0.0
var _rotation_step: int = -1

var _shift_towards: Vector2i = Vector2i.ZERO
var _shift_timer: float = 0.0
var _shift_step: int = -1

var _step: int = 0

@onready var _handle: Sprite2D = $Handle
@onready var _collision_area: Area2D = $Handle/Area2D
@onready var _attached_figure: Figure = null

const PI2 = PI * 2
const HALF_PI = PI / 2

func _ready():
	_handle.modulate = color


func _process(delta):
	_do_rotate(delta)
	_do_shift(delta)


func _do_rotate(delta: float):
	if _direction == _rotating_towards:
		return

	var angle_from = _direction * HALF_PI
	var angle_to = _rotating_towards * HALF_PI

	if _direction == 3 and _rotating_towards == 0:
		angle_to += PI2
	elif _direction == 0 and _rotating_towards == 3:
		angle_from += PI2

	_handle.rotation = lerpf(angle_from, angle_to, _rotating_timer)
	_rotating_timer += delta * Main.simulation_speed

	if _rotating_timer >= 1.0:
		_complete_rotation()


func _do_shift(delta: float):
	if _shift == _shift_towards:
		return

	var normalized_shift = Vector2(
		signi(_shift_towards.x - _shift.x),
		signi(_shift_towards.y - _shift.y))

	var handle_offset: Vector2
	if _shift_timer < 0.5:
		handle_offset = Vector2.ZERO.lerp(normalized_shift, _shift_timer * 2)
	else:
		handle_offset = normalized_shift.lerp(Vector2.ZERO, _shift_timer * 2 - 1)

	_handle.transform.origin = handle_offset * Conveyor.CELL_SIZE

	_shift_timer += delta * Main.simulation_speed
	if _shift_timer >= 1.0:
		_complete_shift()


func set_color(c: Color):
	color = c


func on_enter_cell(_cell: Conveyor):
	pass


func on_exit_cell(_cell: Conveyor):
	_step += 1
	_complete_rotation()
	pass


func rotate_handle(diff: int):
	if _rotation_step == _step:
		return
	_rotation_step = _step
	_rotating_towards = (4 + _direction + diff) % 4


func shift_handle(diff: Vector2i):
	if _shift_step == _step:
		return
	_shift_step = _step
	_shift_towards = _shift + diff


func grab_figure() -> bool:
	if _attached_figure != null:
		return false

	var bodies = _collision_area.get_overlapping_bodies()

	for body in bodies:
		var body_parent = body.get_parent()
		if body_parent is FigurePart:
			var figure = body_parent.get_parent()
			if not figure is Figure:
				continue

			_attached_figure = figure
			_change_figure_parent(_attached_figure, _handle)

			_align_attached_figure()
			return true

	return false


func release_figure():
	if _attached_figure == null:
		return

	_change_figure_parent(_attached_figure, Main.detached_figures_root)

	_align_attached_figure()
	_attached_figure = null


func _align_attached_figure():
	if _attached_figure == null:
		return
	var figure_origin = _attached_figure.global_transform.origin
	_attached_figure.global_transform.origin = Main.shift + figure_origin.snapped(Vector2(Conveyor.CELL_SIZE / 2))


func _complete_rotation():
	_direction = _rotating_towards
	_handle.rotation = _direction * HALF_PI
	_rotating_timer = 0.0


func _complete_shift():
	_shift = _shift_towards
	_handle.transform.origin = Vector2()
	_shift_timer = 0.0


func _change_figure_parent(figure: Figure, new_parent: Node2D):
	call_deferred("_reparent", figure, new_parent, figure.get_global_transform())


func _reparent(node: Figure, new_parent: Node2D, old_transform: Transform2D):
	node.get_parent().remove_child(node)
	new_parent.add_child(node)
	node.transform = new_parent.global_transform.inverse() * old_transform
