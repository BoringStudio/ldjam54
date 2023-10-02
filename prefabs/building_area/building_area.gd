extends Node2D
class_name BuildingArea

const ConveyorPrefab = preload("res://prefabs/conveyor/conveyor.tscn")

@export var width: int = 10
@export var height: int = 10

var running = false

var _grid: Array[Conveyor]
var _tick_time: float = 0.0

var _platforms: Array[Platform] = []
var _platform_indices: Array[Vector2i] = []
var _platform_last_visited_cells: Array[Conveyor] = []

@onready var _grid_offset = transform.origin - Vector2(Conveyor.CELL_SIZE) * Vector2(width, height) * 0.5 + Vector2(Conveyor.CELL_SIZE) * 0.5

func _ready():
	var total := width * height
	_grid.resize(total)
	for i in range(total):
		_grid[i] = null

	# _spawn_cell(Vector2i(0, 0), Conveyor.Item.TurnLeft, Conveyor.DIR_LEFT)
	# _spawn_cell(Vector2i(0, 1), Conveyor.Item.TurnLeft, Conveyor.DIR_DOWN)
	# _spawn_cell(Vector2i(1, 1), Conveyor.Item.PullRight, Conveyor.DIR_RIGHT)
	# _spawn_cell(Vector2i(2, 1), Conveyor.Item.TurnRight, Conveyor.DIR_RIGHT)
	# _spawn_cell(Vector2i(2, 2), Conveyor.Item.RotateLeft, Conveyor.DIR_DOWN)
	# _spawn_cell(Vector2i(2, 3), Conveyor.Item.TurnLeft, Conveyor.DIR_DOWN)
	# _spawn_cell(Vector2i(3, 3), Conveyor.Item.TurnLeft, Conveyor.DIR_RIGHT)

	# _spawn_cell(Vector2i(3, 2), Conveyor.Item.Straight, Conveyor.DIR_UP)

	# _spawn_cell(Vector2i(3, 1), Conveyor.Item.Straight, Conveyor.DIR_UP)
	# _spawn_cell(Vector2i(3, 0), Conveyor.Item.TurnLeft, Conveyor.DIR_UP)
	# _spawn_cell(Vector2i(2, 0), Conveyor.Item.RotateLeft, Conveyor.DIR_LEFT)
	# _spawn_cell(Vector2i(1, 0), Conveyor.Item.PullRight, Conveyor.DIR_LEFT)


func _process(delta):
	if not running:
		return

	var next_tick_time = _tick_time + delta * Main.simulation_speed

	for i in range(_platforms.size()):
		var platform = _platforms[i]
		var platform_origin = _platform_indices[i]
		var last_visited_cell = _platform_last_visited_cells[i]

		var current_cell = get_cell(platform_origin)

		# Update last visited cell if changed
		if last_visited_cell != current_cell:
			platform.on_exit_cell(last_visited_cell)

			if current_cell != null and \
				(last_visited_cell == null or \
					last_visited_cell.get_next_grid_index() == current_cell.get_start_direction()):

				if current_cell.occupied:
					continue
				if last_visited_cell != null:
					last_visited_cell.occupied = false

				platform.on_enter_cell(current_cell)
				last_visited_cell = current_cell
				_platform_last_visited_cells[i] = last_visited_cell
			else:
				# TODO: emit some kind of signal
				current_cell = null

			if current_cell != null:
				current_cell.reset()

		if current_cell == null:
			# TODO: emit some kind of signal
			continue

		current_cell.occupied = true
		current_cell.move_platform(_tick_time, platform)
		if next_tick_time > 1.0:
			if not current_cell.next_tick():
				_platform_indices[i] += current_cell.get_next_grid_index()

	_tick_time = next_tick_time
	if _tick_time > 1.0:
		_tick_time = fmod(_tick_time, 1.0)


func build_conveyor(pos: Vector2, ty: Conveyor.Item, rot: int) -> bool:
	var index = _position_to_index(pos)
	if not check_index(index):
		return false

	_spawn_cell(index, ty, rot)
	return true


func erase_conveyor(pos: Vector2) -> bool:
	var index = _position_to_index(pos)
	var conv = get_cell(index)
	if conv != null:
		conv.get_parent().remove_child(conv)
		conv.queue_free()
		_grid[index.y * width + index.x] = null
		return true
	else:
		return false


func is_position_inside(pos: Vector2) -> bool:
	return check_index(_position_to_index(pos))


func add_platform(pos: Vector2, platform: Platform) -> bool:
	var index = _position_to_index(pos)
	if not check_index(index):
		return false

	if _platform_indices.has(index):
		return false

	_platforms.push_back(platform)
	_platform_indices.push_back(index)
	_platform_last_visited_cells.push_back(null)
	platform.position = _grid_offset + Vector2(index) * Conveyor.CELL_SIZE
	return true


func erase_platform(pos: Vector2) -> bool:
	var index = _position_to_index(pos)
	if not check_index(index):
		return false

	var i = _platform_indices.find(index)
	if i < 0:
		return false

	var platform = _platforms[i]
	platform.get_parent().remove_child(platform)
	platform.queue_free()

	_platforms.remove_at(i)
	_platform_indices.remove_at(i)
	_platform_last_visited_cells.remove_at(i)
	return true


func get_dimentions() -> Vector2:
	return Vector2(width, height) * Conveyor.CELL_SIZE


func get_cell(index: Vector2i):
	if not check_index(index):
		return null
	return _grid[index.y * width + index.x]


func get_cell_by_position(pos: Vector2):
	var index = _position_to_index(pos)
	return get_cell(index)


func set_cell(index: Vector2i, item: Conveyor):
	if not check_index(index):
		return null
	_grid[index.y * width + index.x] = item
	item.transform.origin = _grid_offset + Vector2(index) * Conveyor.CELL_SIZE


func check_index(index: Vector2i) -> bool:
	return index.x >= 0 and index.y >= 0 and index.x < width and index.y < height


func _spawn_cell(index: Vector2i, ty: Conveyor.Item, rot: int):
	var conv = get_cell(index)
	if conv == null:
		conv = ConveyorPrefab.instantiate()
		add_child(conv)
		set_cell(index, conv)

	conv.set_params(ty, rot)


func _position_to_index(pos: Vector2) -> Vector2i:
	const HALF_CELL_SIZE = Conveyor.CELL_SIZE / 2
	var relative_pos = (pos - _grid_offset - HALF_CELL_SIZE).snapped(Conveyor.CELL_SIZE) / Conveyor.CELL_SIZE
	return Vector2i(relative_pos)
