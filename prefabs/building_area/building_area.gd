extends Node2D

const Conveyor = preload("res://prefabs/conveyor/conveyor.gd")

@export var width: int = 10
@export var height: int = 10

@export var platform: Node2D

var _cells: Array[Conveyor]
var _platform_origin: Vector2i = Vector2i(width >> 1, height >> 1)
var _tick_time: float = 0.0

func _ready():
	var total := width * height
	_cells.resize(width * height)
	for i in range(total):
		_cells[i] = null


func _process(_delta):
	var current_cell = _cells[_platform_origin.y * width + _platform_origin.x]
	if current_cell == null:
		# TODO: emit some kind of signal
		return

	current_cell.move_platform(_platform_origin, _tick_time, platform)
	_tick_time += Main.simulation_speed
	if _tick_time > 1.0:
		_tick_time = fmod(_tick_time, 1.0)
		_platform_origin += current_cell.get_next_grid_index()

	pass


static func rotate_dir(dir: int, amount: int) -> int:
	dir += amount
	return dir % 4
