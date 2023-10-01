extends Node2D

var simulation_speed: float = 2.0

var _figure_part_id: int = 0


func get_next_figure_id():
    _figure_part_id += 1
    return _figure_part_id
