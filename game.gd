extends Node2D

const Platform = preload("res://prefabs/platform/platform.tscn")

@export var padding = Vector2(100, 100)

@onready var _camera: Camera2D = $Camera
@onready var _building_area: BuildingArea = $BuildingArea
@onready var _figures: Node2D = $Figures

func _ready():
	Main.detached_figures_root = _figures

	_sync_camera_zoom()
	_camera.get_viewport().size_changed.connect(_sync_camera_zoom)

	# Create platform
	for i in range(1):
		var platform = Platform.instantiate()
		add_child(platform)
		_building_area.add_platform(Vector2i(i, 0), platform)


func _process(delta):
	pass


func _sync_camera_zoom():
	var screen_size = _camera.get_viewport().get_visible_rect().size
	if screen_size.x == 0 or screen_size.y == 0:
		return

	var dimentions = _building_area.get_dimentions() + padding * 2

	var dimentions_ratio = dimentions / screen_size
	var max_ratio = maxf(dimentions_ratio.x, dimentions_ratio.y)
	_camera.zoom = Vector2.ONE / Vector2(max_ratio, max_ratio)
