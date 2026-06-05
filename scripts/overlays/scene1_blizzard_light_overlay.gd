extends Control

const FRAME_INTERVAL_SEC := 0.2
const FRAME_1: Texture2D = preload("res://assets/art/backgrounds/scene_01/bg_s1_blizzard_light_1.png")
const FRAME_2: Texture2D = preload("res://assets/art/backgrounds/scene_01/bg_s1_blizzard_light_2.png")
const FRAME_3: Texture2D = preload("res://assets/art/backgrounds/scene_01/bg_s1_blizzard_light_3.png")
const FRAME_SEQUENCE: Array[Texture2D] = [FRAME_1, FRAME_2, FRAME_3, FRAME_2]

@onready var light: TextureRect = $Light

var _frame_index := 0
var _frame_timer: Timer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_ensure_timer()
	_apply_current_frame()


func start_flicker() -> void:
	_ensure_timer()
	_frame_index = 0
	_apply_current_frame()
	visible = true
	_frame_timer.start()


func stop_flicker() -> void:
	if _frame_timer != null:
		_frame_timer.stop()
	visible = false


func _ensure_timer() -> void:
	if _frame_timer != null:
		return

	_frame_timer = Timer.new()
	_frame_timer.wait_time = FRAME_INTERVAL_SEC
	_frame_timer.one_shot = false
	_frame_timer.autostart = false
	_frame_timer.timeout.connect(_on_frame_timer_timeout)
	add_child(_frame_timer)


func _on_frame_timer_timeout() -> void:
	_frame_index = (_frame_index + 1) % FRAME_SEQUENCE.size()
	_apply_current_frame()


func _apply_current_frame() -> void:
	if light == null:
		return
	light.texture = FRAME_SEQUENCE[_frame_index]
