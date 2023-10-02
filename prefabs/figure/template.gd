@tool
extends Node2D

class_name Template

signal complete()

@export var pallete: Array[Color]

@export var texture: Texture
@export var area_shape: RectangleShape2D

@export var width: int = 0
@export var height: int = 0
@export var colors: Array[Vector4i] = []

@export var change_index: int = 0

@onready var _grid_offset = _compute_grid_offset()
var _last_change_index: int = 0

var _areas: Array[Area2D] = []
var _flip = false
var _done = false

func _ready():
	_sync_sprites()


func _process(_delta):
	if Engine.is_editor_hint():
		if _last_change_index != change_index:
			_last_change_index = change_index
			_sync_sprites()


func _physics_process(_delta):
	if _done:
		return

	if _flip:
		for area in _areas:
			area.set_collision_layer_value(1, false)

		if _check_overlapping_figure() > 0:
			complete.emit()
			_done = true
	else:
		for area in _areas:
			area.set_collision_layer_value(1, true)

	_flip = not _flip


func _check_overlapping_figure() -> int:
	for y in range(height):
		for x in range(width):
			var target_color = colors[y * width + x]
			var cell_colors = _get_cell_colors(Vector2i(x, y))
			if target_color != cell_colors:
				return 0
	return 1


func _get_cell_colors(index: Vector2i) -> Vector4i:
	var result = -Vector4i.ONE
	var offset = (index.y * width + index.x) * 4
	result.x = _get_area_color(offset)
	result.y = _get_area_color(offset + 1)
	result.z = _get_area_color(offset + 2)
	result.w = _get_area_color(offset + 3)
	return result


func _get_area_color(i: int) -> int:
	var area = _areas[i]

	for body in area.get_overlapping_bodies():
		var body_parent = body.get_parent()
		if body_parent is FigurePart:
			return body_parent.color

	return -1


func _sync_sprites():
	_areas = []
	var total = width * height
	while colors.size() < total:
		colors.push_back(-Vector4i.ONE)
	colors.resize(total)

	for child in get_children():
		remove_child(child)
		child.queue_free()

	for y in range(height):
		for x in range(width):
			_spawn_square(Vector2i(x, y), colors[y * width + x])


#  X
# W Y
#  Z
func _spawn_square(index: Vector2i, c: Vector4i):
	var flip_diagonal = false
	var left_color = -1
	var right_color = -1
	if c.x == c.y:
		right_color = c.x
		if c.z == c.w:
			left_color = c.z
	elif c.x == c.w:
		flip_diagonal = true
		left_color = c.x
		if c.y == c.z:
			right_color = c.y

	if left_color >= 0:
		_spawn_triangle(index, true, not flip_diagonal, left_color)
	if right_color >= 0:
		_spawn_triangle(index, false, flip_diagonal, right_color)

	for i in range(4):
		_spawn_area(index, i)


func _spawn_triangle(index: Vector2i, flip_h: bool, flip_v: bool, c: int) -> bool:
	if c >= pallete.size():
		return false

	var sprite = Sprite2D.new()
	sprite.texture = Conveyor.TEXTURE.duplicate()
	sprite.texture.region.size = Conveyor.CELL_SIZE
	sprite.texture.region.position = Vector2(1, 0) * Conveyor.CELL_SIZE
	sprite.flip_v = flip_v
	sprite.flip_h = flip_h
	sprite.modulate = pallete[c]

	add_child(sprite)
	sprite.global_position = _grid_offset + Vector2(index) * Vector2(Conveyor.CELL_SIZE)
	return true


func _spawn_area(index: Vector2i, i: int):
	const AREA_UNIT = Conveyor.CELL_SIZE.x / 4
	const OFFSETS = [Vector2(0, -AREA_UNIT), Vector2(AREA_UNIT, 0), Vector2(0, AREA_UNIT), Vector2(-AREA_UNIT, 0)]

	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = area_shape

	var area = Area2D.new()
	area.add_child(collision_shape)
	add_child(area)

	area.global_position = _grid_offset + Vector2(index) * Vector2(Conveyor.CELL_SIZE) + OFFSETS[i]
	_areas.push_back(area)


func _compute_grid_offset() -> Vector2:
	return transform.origin - Vector2(Conveyor.CELL_SIZE) * Vector2(width, height) * 0.5 + Vector2(Conveyor.CELL_SIZE) * 0.5
