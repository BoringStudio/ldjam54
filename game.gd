extends Node2D

const Platform = preload("res://prefabs/platform/platform.tscn")

@export var padding = Vector2(100, 100)

@onready var camera: Camera2D = $Camera
@onready var building_area: BuildingArea = $BuildingArea

func _ready():
	_sync_camera_zoom()
	camera.get_viewport().size_changed.connect(_sync_camera_zoom)

	# Create platform
	var platform = Platform.instantiate()
	add_child(platform)
	building_area.set_platform(platform)


func _process(delta):
	pass


func _sync_camera_zoom():
	var screen_size = camera.get_viewport().get_visible_rect().size
	if screen_size.x == 0 or screen_size.y == 0:
		return

	var dimentions = building_area.get_dimentions() + padding * 2

	var dimentions_ratio = dimentions / screen_size
	var max_ratio = maxf(dimentions_ratio.x, dimentions_ratio.y)
	camera.zoom = Vector2.ONE / Vector2(max_ratio, max_ratio)
