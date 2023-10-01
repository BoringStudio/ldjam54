extends Node2D

class_name Figure

var _parts: Array[FigurePart] = []

var _pivot_part: FigurePart = null
var _target_pivot_part: FigurePart = null

var _pivot_offset := Vector2.ZERO
var _target_pivot_offset := Vector2.ZERO
var _shift_timer := 0.0
var _shift_step := -1

@onready var _handle: Node2D = $Handle


func _ready():
	pass


func _process(_delta):
	pass


func _traverse_figures():
	var visited: Dictionary = {}
	var stack: Array[FigurePart] = []
	if _pivot_part != null:
		stack.push_back(_pivot_part)

	while not stack.is_empty():
		var node = stack.pop_back()

		if node.top_neighbour != null and not node.top_neighbour.part_id in visited:
			visited[node.top_neighbour.part_id] = true
			stack.push_back(node.top_neighbour)

		if node.left_neighbour != null and not node.left_neighbour.part_id in visited:
			visited[node.left_neighbour.part_id] = true
			stack.push_back(node.left_neighbour)

		if node.diagonal_neighbour != null and not node.diagonal_neighbour.part_id in visited:
			visited[node.diagonal_neighbour.part_id] = true
			stack.push_back(node.diagonal_neighbour)
