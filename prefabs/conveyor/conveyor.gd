@tool
extends Sprite2D

class_name Conveyor

const DIR_UP = 0
const DIR_RIGHT = 1
const DIR_DOWN = 2
const DIR_LEFT = 3

const CELL_SIZE = Vector2(256.0, 256.0)

const TEXTURE: AtlasTexture = preload("res://prefabs/conveyor/conveyor_texture.tres")

@export var ty: Item = Item.Straight
@export_enum("Up:0", "Right:1", "Down:2", "Left:3") var rot: int = DIR_RIGHT

var _tick: int = 0

enum Item {
	Straight,
	TurnRight,
	TurnLeft,
	# RotateRight,
	# RotateLeft,
	# PushRight,
	# PushLeft,
	# Semaphore,
}


func _init(t: Item, r: int):
	texture = TEXTURE.duplicate()
	ty = t
	rot = r


func _ready():
	_sync_sprite_state()


func _process(_delta):
	if Engine.is_editor_hint():
		_sync_sprite_state()


func reset():
	_tick = 0


func move_platform(tick_time: float, platform: Node2D):
	var cell_offset = Vector2()
	if tick_time < 0.5:
		var start_offset = Conveyor.make_direction((rot + 2) % 4)
		cell_offset = start_offset.lerp(Vector2.ZERO, tick_time * 2)
	else:
		var r := rot
		match ty:
			Item.TurnRight:
				r = Conveyor.make_rot_right(r)
			Item.TurnLeft:
				r = Conveyor.make_rot_left(r)
		var end_offset = Conveyor.make_direction(r)
		cell_offset = Vector2.ZERO.lerp(end_offset, tick_time * 2 - 1)

	platform.transform.origin = transform.origin + cell_offset * CELL_SIZE / 2


func next_tick() -> bool:
	return false


func get_next_grid_index() -> Vector2i:
	var r = rot
	match ty:
		Item.TurnRight:
			r = Conveyor.make_rot_right(r)
		Item.TurnLeft:
			r = Conveyor.make_rot_left(r)
	return Conveyor.make_grid_direction(r)


func _sync_sprite_state():
	var tile_index = Vector2i()
	match ty:
		Item.Straight:
			tile_index = Vector2(0, 1)
		Item.TurnRight:
			tile_index = Vector2(1, 1)
		Item.TurnLeft:
			tile_index = Vector2(1, 1)
			flip_h = true

	rotation_degrees = 90 * rot
	texture.region.size = CELL_SIZE
	texture.region.position = Vector2(tile_index) * CELL_SIZE


static func make_direction(r: int) -> Vector2:
	match r:
		DIR_UP:
			return Vector2.UP
		DIR_RIGHT:
			return Vector2.RIGHT
		DIR_DOWN:
			return Vector2.DOWN
		DIR_LEFT:
			return Vector2.LEFT
		_:
			return Vector2.ZERO


static func make_grid_direction(r: int) -> Vector2i:
	match r:
		DIR_UP:
			return Vector2i.UP
		DIR_RIGHT:
			return Vector2i.RIGHT
		DIR_DOWN:
			return Vector2i.DOWN
		DIR_LEFT:
			return Vector2i.LEFT
		_:
			return Vector2i.ZERO


static func make_rot_right(r: int) -> int:
	return (r + 1) % 4


static func make_rot_left(r: int) -> int:
	return (4 + r - 1) % 4
