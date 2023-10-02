extends Node2D

const PlatformPrefab = preload("res://prefabs/platform/platform.tscn")
const ConveyorPrefab = preload("res://prefabs/conveyor/conveyor.tscn")

@export var conveyor_proto_color: Color = Color.WHITE

@export var padding = Vector2(100, 100)
@export var shift = Vector2.ZERO

@onready var _camera: Camera2D = $Camera
@onready var _building_area: BuildingArea = $BuildingArea
@onready var _figures: Node2D = $Figures
@onready var _spawners: Node2D = $Spawners

var _platform_mode = false
var _platform: Platform = null
var _selected_conveyor_proto: Conveyor = null
var _last_rotation: int = 0

var _running: bool = false

func _ready():
	Main.detached_figures_root = _figures
	Main.shift = shift

	_sync_camera_zoom()
	_camera.get_viewport().size_changed.connect(_sync_camera_zoom)

	_reset()


func _process(_delta):
	if not _running:
		var mouse_pos = _get_aligned_mouse_pos()

		if _platform != null:
			_platform.global_transform.origin = mouse_pos

		if _selected_conveyor_proto != null:
			_selected_conveyor_proto.global_transform.origin = mouse_pos


func _input(event):
	if event.is_action_pressed("TogglePlay"):
		_toggle_play()

	_sync_visibility()

	if not _running:
		if Input.is_action_pressed("Remove"):
			_erase_conveyor()

		if event.is_action_pressed("Copy"):
			_pick_same_conveyor_proto()

		if _platform_mode and _platform != null:
			if event.is_action_pressed("Place"):
				_place_platform()
		elif not _platform_mode and _selected_conveyor_proto != null:
			if event.is_action_pressed("Flip"):
				_selected_conveyor_proto.flip()
			elif event.is_action_pressed("RotateRight"):
				_selected_conveyor_proto.rotate_direction(1)
			elif event.is_action_pressed("RotateLeft"):
				_selected_conveyor_proto.rotate_direction(-1)
			elif event.is_action_pressed("Place"):
				_place_selected_conveyor_proto()


func _sync_camera_zoom():
	var screen_size = _camera.get_viewport().get_visible_rect().size
	if screen_size.x == 0 or screen_size.y == 0:
		return

	var dimentions = _building_area.get_dimentions() + Conveyor.CELL_SIZE * 2 + padding * 2

	var dimentions_ratio = dimentions / screen_size
	var max_ratio = maxf(dimentions_ratio.x, dimentions_ratio.y)
	_camera.zoom = Vector2.ONE / Vector2(max_ratio, max_ratio)


func _toggle_play():
	_set_running(not _running)


func _set_running(r: bool):
	if _running == r:
		return
	_running = r
	_building_area.running = r
	_reset()


func _reset():
	_building_area.reset()
	for child in _spawners.get_children():
		if child is PartSpawner:
			child.respawn()


func _place_platform():
	if not _platform_mode:
		return

	var platform = PlatformPrefab.instantiate()
	add_child(platform)
	if not _building_area.add_platform(_get_aligned_mouse_pos(), platform):
		platform.get_parent().remove_child(platform)
		platform.queue_free()


func _place_selected_conveyor_proto():
	if _platform_mode or _selected_conveyor_proto == null:
		return

	var placed = _building_area.build_conveyor(
		_selected_conveyor_proto.global_position,
		_selected_conveyor_proto.ty,
		_selected_conveyor_proto.rot)

	if placed:
		_last_rotation = _selected_conveyor_proto.get_out_rot()
		_selected_conveyor_proto.set_direction(_last_rotation)


func _pick_same_conveyor_proto():
	_platform_mode = false
	var conv = _building_area.get_cell_by_position(_get_aligned_mouse_pos())
	if conv != null:
		_set_selected_conveyour_proto(conv.ty)


func _erase_conveyor():
	var mouse_pos = _get_aligned_mouse_pos()
	if _building_area.erase_platform(mouse_pos):
		return
	_building_area.erase_conveyor(mouse_pos)


func _sync_visibility():
	var inside_building_area = not _running and _building_area.is_position_inside(_get_aligned_mouse_pos())
	if _platform != null:
		_platform.visible = _platform_mode and inside_building_area
	if _selected_conveyor_proto != null:
		_selected_conveyor_proto.visible = not _platform_mode and inside_building_area


func _set_selected_conveyour_proto(ty: Conveyor.Item):
	_platform_mode = false
	if _platform != null:
		_platform.visible = false

	_release_selected_conveyor_proto()
	var conv = ConveyorPrefab.instantiate()
	conv.set_params(ty, _last_rotation, conveyor_proto_color)
	add_child(conv)
	_selected_conveyor_proto = conv
	_sync_visibility()


func _release_selected_conveyor_proto():
	if _selected_conveyor_proto == null:
		return
	remove_child(_selected_conveyor_proto)
	_selected_conveyor_proto.queue_free()


func _get_aligned_mouse_pos():
	const HALF_CELL_SIZE = Conveyor.CELL_SIZE / 2
	return shift + (get_global_mouse_position() - HALF_CELL_SIZE).snapped(Conveyor.CELL_SIZE) + HALF_CELL_SIZE


func _on_play_pressed():
	_set_running(true)


func _on_reset_pressed():
	_set_running(false)


func _on_select_platform_pressed():
	_platform_mode = true
	if _selected_conveyor_proto != null:
		_selected_conveyor_proto.visible = false

	if _platform == null:
		_platform = PlatformPrefab.instantiate()
		_platform.set_color(conveyor_proto_color)
		add_child(_platform)

	_sync_visibility()


func _on_select_straight_pressed():
	_set_selected_conveyour_proto(Conveyor.Item.Straight)


func _on_select_turn_pressed():
	_set_selected_conveyour_proto(Conveyor.Item.TurnRight)


func _on_select_rotate_pressed():
	_set_selected_conveyour_proto(Conveyor.Item.RotateRight)


func _on_select_push_pressed():
	_set_selected_conveyour_proto(Conveyor.Item.PushRight)


func _on_select_pull_pressed():
	_set_selected_conveyour_proto(Conveyor.Item.PullRight)
