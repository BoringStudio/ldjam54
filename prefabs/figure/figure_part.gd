@tool
extends Node2D

class_name FigurePart

var top_neighbour: FigurePart
var left_neighbour: FigurePart
var diagonal_neighbour: FigurePart

var part_id: int:
	get:
		return _part_id

var _part_id: int = Main.get_next_figure_id()

func _ready():
	pass
