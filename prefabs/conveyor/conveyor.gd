@tool
extends Node2D

class_name Conveyor

const DIR_UP = 0
const DIR_RIGHT = 1
const DIR_DOWN = 2
const DIR_LEFT = 3

const CELL_SIZE = Vector2(256.0, 256.0)

const TEXTURE: AtlasTexture = preload("res://prefabs/conveyor/conveyor_texture.tres")

@export var ty: Item = Item.Straight
@export_enum("Up:0", "Right:1", "Down:2", "Left:3") var rot: int = DIR_RIGHT

var occupied: bool = false

var _figure: Figure = null
var _figure_offset: Vector2i = Vector2i()
var _tick: int = 0

@onready var _sprite = $Sprite

enum Item {
	Straight,
	TurnLeft,
	TurnRight,
	RotateLeft,
	RotateRight,
	PushLeft,
	PushRight,
	PullRight,
	PullLeft,
	# Semaphore,
}


func _ready():
	_sprite.texture = TEXTURE.duplicate()
	_sync_sprite_state()


func _process(_delta):
	if Engine.is_editor_hint():
		_sync_sprite_state()


func set_params(t: Item, r: int):
	ty = t
	rot = r


func reset():
	_tick = 0
	occupied = false


func next_tick() -> bool:
	_tick += 1
	match ty:
		Item.RotateLeft, Item.RotateRight, \
		Item.PushLeft, Item.PushRight, Item.PullLeft, Item.PullRight:
			return _tick < 2
		_:
			return _tick < 1


func move_platform(tick_time: float, platform: Platform):
	match ty:
		Item.Straight:
			_do_move_straight(tick_time, platform)
		Item.TurnLeft:
			_do_move_turn(tick_time, platform, false)
		Item.TurnRight:
			_do_move_turn(tick_time, platform, true)
		Item.RotateLeft:
			_do_move_rotate(tick_time, platform, false)
		Item.RotateRight:
			_do_move_rotate(tick_time, platform, true)
		Item.PushLeft:
			_do_move_push(tick_time, platform, false)
		Item.PushRight:
			_do_move_push(tick_time, platform, true)
		Item.PullLeft:
			_do_move_pull(tick_time, platform, false)
		Item.PullRight:
			_do_move_pull(tick_time, platform, true)


func _do_move_straight(tick_time: float, platform: Platform):
	var start_offset = Conveyor.make_direction(Conveyor.make_rot_inv(rot))
	var end_offset = Conveyor.make_direction(rot)

	_set_relative_platform_position(platform, start_offset.lerp(end_offset, tick_time))


func _do_move_turn(tick_time: float, platform: Platform, right: bool):
	var cell_offset = Vector2()
	if tick_time < 0.5:
		var start_offset = Conveyor.make_direction(Conveyor.make_rot_inv(rot))
		cell_offset = start_offset.lerp(Vector2.ZERO, tick_time * 2)
	else:
		var r := Conveyor.make_rot_right(rot) if right else Conveyor.make_rot_left(rot)
		var end_offset = Conveyor.make_direction(r)
		cell_offset = Vector2.ZERO.lerp(end_offset, tick_time * 2 - 1)

	_set_relative_platform_position(platform, cell_offset)


func _do_move_rotate(tick_time: float, platform: Platform, right: bool):
	if _tick == 0:
		if tick_time < 0.5:
			var start_offset = Conveyor.make_direction(Conveyor.make_rot_inv(rot))
			_set_relative_platform_position(platform, start_offset.lerp(Vector2.ZERO, tick_time * 2))
		else:
			platform.rotate_handle(1 if right else -1)
	elif tick_time >= 0.5:
		var end_offset = Conveyor.make_direction(rot)
		_set_relative_platform_position(platform, Vector2.ZERO.lerp(end_offset, tick_time * 2 - 1))


func _do_move_push(tick_time: float, platform: Platform, right: bool):
	if _tick == 0:
		if tick_time < 0.5:
			var start_offset = Conveyor.make_direction(Conveyor.make_rot_inv(rot))
			_set_relative_platform_position(platform, start_offset.lerp(Vector2.ZERO, tick_time * 2))
		else:
			var r = Conveyor.make_rot_right(rot)
			if not right:
				r = Conveyor.make_rot_inv(r)
			platform.shift_handle(Conveyor.make_grid_direction(r))
	elif _tick == 1 and tick_time < 0.5:
		platform.release_figure()
	else:
		platform.grab_figure()
		var end_offset = Conveyor.make_direction(rot)
		_set_relative_platform_position(platform, Vector2.ZERO.lerp(end_offset, tick_time * 2 - 1))


func _do_move_pull(tick_time: float, platform: Platform, right: bool):
	if _tick == 0:
		if tick_time < 0.5:
			var start_offset = Conveyor.make_direction(Conveyor.make_rot_inv(rot))
			_set_relative_platform_position(platform, start_offset.lerp(Vector2.ZERO, tick_time * 2))
		else:
			platform.release_figure()
			var r = Conveyor.make_rot_right(rot)
			if not right:
				r = Conveyor.make_rot_inv(r)
			platform.shift_handle(Conveyor.make_grid_direction(r))
	elif _tick == 1 and tick_time < 0.1:
		platform.grab_figure()
	elif tick_time >= 0.5:
		platform.grab_figure()
		var end_offset = Conveyor.make_direction(rot)
		_set_relative_platform_position(platform, Vector2.ZERO.lerp(end_offset, tick_time * 2 - 1))


func get_start_direction() -> Vector2i:
	return Conveyor.make_grid_direction(rot)


func get_next_grid_index() -> Vector2i:
	var r = rot
	match ty:
		Item.TurnRight:
			r = Conveyor.make_rot_right(r)
		Item.TurnLeft:
			r = Conveyor.make_rot_left(r)
	return Conveyor.make_grid_direction(r)


func _sync_sprite_state():
	if _sprite == null or _sprite.texture == null:
		return

	var tile_index = Vector2i()
	var region_size = Vector2i.ONE
	var region_offset = Vector2i.ZERO
	match ty:
		Item.Straight:
			tile_index = Vector2(0, 1)
		Item.TurnRight:
			tile_index = Vector2(1, 1)
		Item.TurnLeft:
			tile_index = Vector2(1, 1)
			_sprite.flip_h = true
		Item.RotateRight:
			tile_index = Vector2(2, 1)
		Item.RotateLeft:
			tile_index = Vector2(2, 1)
			_sprite.flip_h = true
		Item.PushRight:
			tile_index = Vector2(3, 1)
			region_size.x = 2
			region_offset.x = 1
		Item.PushLeft:
			tile_index = Vector2(3, 1)
			region_size.x = 2
			region_offset.x = -1
			_sprite.flip_h = true
		Item.PullRight:
			tile_index = Vector2(3, 2)
			region_size.x = 2
			region_offset.x = 1
		Item.PullLeft:
			tile_index = Vector2(3, 2)
			region_size.x = 2
			region_offset.x = -1
			_sprite.flip_h = true

	rotation_degrees = 90 * rot
	_sprite.transform.origin += Vector2(region_offset) * CELL_SIZE / 2
	_sprite.texture.region.size = Vector2(region_size) * CELL_SIZE
	_sprite.texture.region.position = Vector2(tile_index) * CELL_SIZE


func _set_relative_platform_position(platform: Platform, cell_offset: Vector2):
	platform.transform.origin = transform.origin + cell_offset * CELL_SIZE / 2


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


static func make_rot_inv(r: int) -> int:
	return (r + 2) % 4


static func make_rot_right(r: int) -> int:
	return (r + 1) % 4


static func make_rot_left(r: int) -> int:
	return (4 + r - 1) % 4
