@tool
extends Node2D

class_name FigurePart

@export var color: Color

var top_neighbour: FigurePart
var left_neighbour: FigurePart
var diagonal_neighbour: FigurePart

@onready var _sprite: Sprite2D = $Sprite
@onready var _body: StaticBody2D = $Triangle
@onready var _area: Area2D = $Area


func _ready():
	_sync_sprite_state()
	_area.connect("body_entered", _on_body_entered)


func _process(_delta):
	if Engine.is_editor_hint():
		_sync_sprite_state()


func get_global_neighbour(dir: int):
	return get_local_neighbour((dir + _compute_rotation()) % 4)


func get_local_neighbour(dir: int):
	match dir:
		Conveyor.DIR_UP:
			return top_neighbour
		Conveyor.DIR_LEFT:
			return left_neighbour
		_:
			return null


func _compute_rotation() -> int:
	const PI_DIV_4: float = PI / 4

	var angle = wrapf(global_rotation, 0.0, TAU)
	if angle < PI_DIV_4:
		return Conveyor.DIR_UP
	elif angle >= PI_DIV_4 and angle < 3 * PI_DIV_4:
		return Conveyor.DIR_RIGHT
	elif angle >= 3 * PI_DIV_4 and angle < 5 * PI_DIV_4:
		return Conveyor.DIR_DOWN
	elif angle >= 5 * PI_DIV_4 and angle < 7 * PI_DIV_4:
		return Conveyor.DIR_LEFT
	else:
		return Conveyor.DIR_UP


func _sync_sprite_state():
	_sprite.modulate = color


func _on_body_entered(body: Node2D):
	if body == _body:
		return

	var our_figure = get_parent()
	if our_figure == Main.detached_figures_root:
		return

	var body_parent = body.get_parent()
	if not body_parent is FigurePart:
		return

	var other_figure = body_parent.get_parent()
	var other_figure_parent = other_figure.get_parent()
	if other_figure_parent != our_figure.get_parent() and other_figure_parent == Main.detached_figures_root:
		for part in other_figure.get_children():
			var part_transform = part.global_transform
			other_figure.remove_child(part)
			our_figure.add_child(part)

			part.global_transform = part_transform
			part.rotation = snappedf(part.rotation, PI / 2)
			part.transform.origin = part.transform.origin.snapped(Vector2(Conveyor.CELL_SIZE))
		other_figure.queue_free()

		pass
