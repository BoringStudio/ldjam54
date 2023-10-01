extends Node2D

class_name Figure

# Packed grid item:
# 1 bit - diagonal
# 16 bit - first
# 16 bit - second

const PACKED_DIAGONAL_MASK: int = 0x100000000
const PACKED_INDEX_MASK: int = 0xffff

var _parts: Array[FigurePart] = []
var _grid: Array[int] = []
var _pivot: Vector2i = Vector2i()

@onready var _handle: Node2D = $Handle

enum Diagonal {
	Right, # /
	Left, # \
}

func _ready():
	pass


func _process(_delta):
	pass


func merge(direction: Vector2i, other: Figure) -> bool:
	return false


func _pack_grid_item(first: int, second: int, diagonal: Diagonal) -> int:
	var result = (first & PACKED_INDEX_MASK) | (second & PACKED_INDEX_MASK) << 16
	if diagonal == Diagonal.Right:
		result |= PACKED_DIAGONAL_MASK
	return result


func _unpack_diagonal(packed: int) -> Diagonal:
	if packed & PACKED_DIAGONAL_MASK == 0:
		return Diagonal.Right
	else:
		return Diagonal.Left


func _unpack_grid_item_first(packed: int):
	packed &= PACKED_INDEX_MASK
	if packed == PACKED_INDEX_MASK:
		return null
	return _parts[packed]


func _unpack_grid_item_second(packed: int):
	packed >>= 16
	return _unpack_grid_item_first(packed)
