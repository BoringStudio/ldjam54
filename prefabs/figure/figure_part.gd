@tool
extends Node2D

class_name FigurePart

const TOP_LEFT: int = 0
const TOP_RIGHT: int = 1
const BOTTOM_RIGHT: int = 2
const BOTTOM_LEFT: int = 3

@export_enum("TopLeft:0", "TopRight:1", "BottomRight:2", "BottomLeft:3") var variant: int = 0

@onready var _sprite = $Sprite

func _ready():
	_sync_sprite_state()


func _process(_delta):
	if Engine.is_editor_hint():
		_sync_sprite_state()


func _sync_sprite_state():
	_sprite.flip_h = variant == TOP_RIGHT or variant == BOTTOM_RIGHT
	_sprite.flip_v = variant == BOTTOM_LEFT or variant == BOTTOM_RIGHT
