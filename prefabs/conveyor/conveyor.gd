@tool
extends Sprite2D

class_name Conveyor

const DIR_UP = 0
const DIR_RIGHT = 1
const DIR_DOWN = 2
const DIR_LEFT = 3

const CELL_SIZE = Vector2(256.0, 256.0)

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


func _ready():
	assert(texture is AtlasTexture)
	_sync_sprite_state()


func _process(_delta):
	if Engine.is_editor_hint():
		_sync_sprite_state()


func reset():
	_tick = 0


func move_platform(index: Vector2i, tick_time: float, platform: Node2D):
	var cell_offset = Vector2(index)

	if tick_time < 0.5:
		var start_offset = Conveyor.make_direction((rot + 2) % 4)
		cell_offset += start_offset.lerp(Vector2.ZERO, tick_time)
	else:
		var r := rot
		match ty:
			Item.TurnRight:
				r = (rot + 1) % 4
			Item.TurnLeft:
				r = (rot - 1) % 4
		var end_offset = Conveyor.make_direction(r)
		cell_offset = Vector2.ZERO.lerp(end_offset, tick_time)

	platform.transform.origin = cell_offset * CELL_SIZE


func next_tick() -> bool:
	return false


func get_next_grid_index() -> Vector2i:
	var r = rot
	match ty:
		Item.TurnRight:
			r = (r + 1) % 4
		Item.TurnLeft:
			r = (r - 1) % 4
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
			return Vector2i(0, 1)
		DIR_RIGHT:
			return Vector2i(1, 0)
		DIR_DOWN:
			return Vector2i(0, -1)
		DIR_LEFT:
			return Vector2i(-1, 0)
		_:
			return Vector2i.ZERO
