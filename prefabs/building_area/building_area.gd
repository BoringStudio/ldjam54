extends Node2D

const Conveyor = preload("res://prefabs/conveyor/conveyor.gd")

@export var width: int = 10
@export var height: int = 10

@export var platform: Platform

var _grid: Array[Conveyor]
var _platform_origin: Vector2i = Vector2i(0, 0)
var _tick_time: float = 0.0
var _last_visited_cell: Conveyor = null

@onready var _grid_offset = transform.origin - Vector2(Conveyor.CELL_SIZE) * Vector2(width, height) * 0.5 + Vector2(Conveyor.CELL_SIZE) * 0.5

func _ready():
	var total := width * height
	_grid.resize(total)
	for i in range(total):
		_grid[i] = null

	_spawn_cell(Vector2i(0, 0), Conveyor.Item.TurnLeft, Conveyor.DIR_LEFT)
	_spawn_cell(Vector2i(0, 1), Conveyor.Item.TurnLeft, Conveyor.DIR_DOWN)
	_spawn_cell(Vector2i(1, 1), Conveyor.Item.PushRight, Conveyor.DIR_RIGHT)
	_spawn_cell(Vector2i(2, 1), Conveyor.Item.RotateRight, Conveyor.DIR_RIGHT)
	_spawn_cell(Vector2i(3, 1), Conveyor.Item.TurnLeft, Conveyor.DIR_RIGHT)
	_spawn_cell(Vector2i(3, 0), Conveyor.Item.TurnLeft, Conveyor.DIR_UP)
	_spawn_cell(Vector2i(2, 0), Conveyor.Item.TurnLeft, Conveyor.DIR_LEFT)
	_spawn_cell(Vector2i(1, 0), Conveyor.Item.Straight, Conveyor.DIR_LEFT)


func _process(delta):
	var current_cell = get_cell(_platform_origin)

	# Update last visited cell if changed
	if _last_visited_cell != current_cell:
		platform.on_exit_cell(_last_visited_cell)

		if _last_visited_cell == null or _last_visited_cell.get_next_grid_index() == current_cell.get_start_direction():
			platform.on_enter_cell(current_cell)
			_last_visited_cell = current_cell
		else:
			# TODO: emit some kind of signal
			current_cell = null

		if current_cell != null:
			current_cell.reset()

	if current_cell == null:
		# TODO: emit some kind of signal
		return

	current_cell.move_platform(_tick_time, platform)
	_tick_time += delta * Main.simulation_speed
	if _tick_time > 1.0:
		_tick_time = fmod(_tick_time, 1.0)
		if not current_cell.next_tick():
			_platform_origin += current_cell.get_next_grid_index()

	pass


func _spawn_cell(index: Vector2i, ty: Conveyor.Item, rot: int):
	var conv = Conveyor.new(ty, rot)
	add_child(conv)
	set_cell(index, conv)


func get_cell(index: Vector2i):
	if not check_index(index):
		return null
	return _grid[index.y * width + index.x]


func set_cell(index: Vector2i, item: Conveyor):
	if not check_index(index):
		return null
	_grid[index.y * width + index.x] = item
	item.transform.origin = _grid_offset + Vector2(index) * Conveyor.CELL_SIZE


func check_index(index: Vector2i) -> bool:
	return index.x >= 0 and index.y >= 0 and index.x < width and index.y < height


static func rotate_dir(dir: int, amount: int) -> int:
	dir += amount
	return dir % 4
