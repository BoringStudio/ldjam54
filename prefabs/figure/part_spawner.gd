extends Node2D
class_name PartSpawner

const FigurePartPrefab = preload("res://prefabs/figure/figure_part.tscn")

@export_enum("Red:0", "Yellow:1", "Green:2") var color: int = 0
@export_enum("Up:0", "Right:1", "Down:2", "Left:3") var rot: int = 0

var _spawned_figure

func _ready():
	pass


func _process(_delta):
	pass


func respawn():
	const HALF_CELL_SIZE = Conveyor.CELL_SIZE / 2

	if _spawned_figure != null:
		var figure = _spawned_figure.get_ref()
		if figure != null:
			figure.get_parent().remove_child(figure)
			figure.queue_free()

	var figure_part = FigurePartPrefab.instantiate()
	figure_part.color = color
	figure_part.global_rotation = rot * PI / 2

	var figure = Figure.new()
	figure.add_child(figure_part)
	figure.global_position = Main.shift + (global_position - HALF_CELL_SIZE).snapped(Conveyor.CELL_SIZE) + HALF_CELL_SIZE

	Main.detached_figures_root.add_child(figure)
	_spawned_figure = weakref(figure)
