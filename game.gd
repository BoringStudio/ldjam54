extends Node2D

const PlatformPrefab = preload("res://prefabs/platform/platform.tscn")
const ConveyorPrefab = preload("res://prefabs/conveyor/conveyor.tscn")

@export var conveyor_proto_color: Color = Color.WHITE

@export var padding = Vector2(100, 100)

@onready var _camera: Camera2D = $Camera
@onready var _building_area: BuildingArea = $BuildingArea
@onready var _figures: Node2D = $Figures

var _selected_conveyor_proto: Conveyor = null
var _last_rotation: int = 0

func _ready():
	Main.detached_figures_root = _figures

	_sync_camera_zoom()
	_camera.get_viewport().size_changed.connect(_sync_camera_zoom)


func _process(_delta):
	if _selected_conveyor_proto != null:
		_selected_conveyor_proto.global_transform.origin = _get_aligned_mouse_pos()


func _input(event):
	if Input.is_action_pressed("Remove"):
		_erase_conveyor()

	if _selected_conveyor_proto != null:
		if event.is_action_pressed("Flip"):
			_selected_conveyor_proto.flip()
		elif event.is_action_pressed("RotateRight"):
			_selected_conveyor_proto.rotate_direction(1)
		elif event.is_action_pressed("RotateLeft"):
			_selected_conveyor_proto.rotate_direction(-1)
		elif event.is_action_pressed("Place"):
			_place_selected_conveyor_proto()
		elif event.is_action_pressed("Copy"):
			_pick_same_conveyor_proto()


func _sync_camera_zoom():
	var screen_size = _camera.get_viewport().get_visible_rect().size
	if screen_size.x == 0 or screen_size.y == 0:
		return

	var dimentions = _building_area.get_dimentions() + Conveyor.CELL_SIZE * 2 + padding * 2

	var dimentions_ratio = dimentions / screen_size
	var max_ratio = maxf(dimentions_ratio.x, dimentions_ratio.y)
	_camera.zoom = Vector2.ONE / Vector2(max_ratio, max_ratio)


func _place_selected_conveyor_proto():
	if _selected_conveyor_proto == null:
		return

	var placed = _building_area.build_conveyor(
		_selected_conveyor_proto.global_position,
		_selected_conveyor_proto.ty,
		_selected_conveyor_proto.rot)

	if placed:
		_last_rotation = _selected_conveyor_proto.get_out_rot()
		_selected_conveyor_proto.set_direction(_last_rotation)


func _pick_same_conveyor_proto():
	var conv = _building_area.get_cell_by_position(_get_aligned_mouse_pos())
	if conv != null:
		_set_selected_conveyour_proto(conv.ty)


func _erase_conveyor():
	_building_area.erase_conveyor(_get_aligned_mouse_pos())


func _set_selected_conveyour_proto(ty: Conveyor.Item):
	_release_selected_conveyor_proto()
	var conv = ConveyorPrefab.instantiate()
	conv.set_params(ty, _last_rotation, conveyor_proto_color)
	add_child(conv)
	_selected_conveyor_proto = conv


func _release_selected_conveyor_proto():
	if _selected_conveyor_proto == null:
		return
	remove_child(_selected_conveyor_proto)
	_selected_conveyor_proto.queue_free()


func _get_aligned_mouse_pos():
	const HALF_CELL_SIZE = Conveyor.CELL_SIZE / 2
	return (get_global_mouse_position() - HALF_CELL_SIZE).snapped(Conveyor.CELL_SIZE) + HALF_CELL_SIZE


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
