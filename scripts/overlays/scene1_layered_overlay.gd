extends Control

const DAY_BACKGROUND: Texture2D = preload("res://assets/art/backgrounds/scene_01/bg_scene1_house_empty_v2.jpg")
const MORNING_BACKGROUND: Texture2D = preload("res://assets/art/backgrounds/scene_01/bg_scene1_morning_interior_v2.jpg")

const FIRE_FRAMES: Array[Texture2D] = [
	preload("res://assets/art/effects/scene_01/fire/fire_01.png"),
	preload("res://assets/art/effects/scene_01/fire/fire_02.png"),
	preload("res://assets/art/effects/scene_01/fire/fire_03.png"),
	preload("res://assets/art/effects/scene_01/fire/fire_04.png"),
]
const FIRE_FRAME_INTERVAL_SEC := 0.12
const FIRE_ALPHA_MIN := 0.70
const FIRE_ALPHA_MAX := 0.88
const FIRE_SCALE_MIN := 0.97
const FIRE_SCALE_MAX := 1.00

@onready var background: TextureRect = $Background
@onready var fire_mask: Control = $FireMask
@onready var fire: TextureRect = $FireMask/Fire
@onready var family_group: TextureRect = $FamilyGroup
@onready var family_group_amulets: TextureRect = $FamilyGroupAmulets
@onready var family_group_sleep: TextureRect = $FamilyGroupSleep
@onready var family_group_wakeup: TextureRect = $FamilyGroupWakeup
@onready var family_group_dressing: TextureRect = $FamilyGroupDressing
@onready var bargyy: TextureRect = $Bargyy

var fade_tween: Tween
var _fire_frame_timer: Timer
var _fire_frame_index := 0
var _fire_effects_active := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_fire_nodes()
	_setup_fire_frame_timer()
	_set_character_layers_alpha(0.0)
	if fire != null and not FIRE_FRAMES.is_empty():
		fire.texture = FIRE_FRAMES[0]
		fire.modulate.a = FIRE_ALPHA_MIN
		fire.scale = Vector2.ONE
	_stop_fire()
	visible = false


func show_overlay() -> void:
	_kill_fade_tween()
	_reset_to_initial_pose()
	_set_character_layers_alpha(0.0)
	background.modulate.a = 1.0
	visible = true
	_start_fire()
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(family_group, "modulate:a", 1.0, 0.6)
	fade_tween.tween_property(bargyy, "modulate:a", 1.0, 0.6)


func show_amulets_pose() -> void:
	_kill_fade_tween()
	_start_fire()
	family_group.visible = true
	family_group_amulets.visible = true
	family_group_sleep.visible = false
	family_group_wakeup.visible = false
	family_group_dressing.visible = false
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(family_group, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(family_group_amulets, "modulate:a", 1.0, 0.6)
	fade_tween.tween_property(family_group_sleep, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(family_group_wakeup, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(family_group_dressing, "modulate:a", 0.0, 0.6)


func show_sleep_pose() -> void:
	_kill_fade_tween()
	_start_fire()
	family_group.visible = true
	family_group_amulets.visible = true
	family_group_sleep.visible = true
	family_group_wakeup.visible = false
	family_group_dressing.visible = false
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(family_group, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(family_group_amulets, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(family_group_sleep, "modulate:a", 1.0, 0.6)
	fade_tween.tween_property(family_group_wakeup, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(family_group_dressing, "modulate:a", 0.0, 0.6)


func show_wakeup_pose() -> void:
	_kill_fade_tween()
	_start_fire()
	background.texture = MORNING_BACKGROUND
	family_group.visible = true
	family_group_amulets.visible = true
	family_group_sleep.visible = true
	family_group_wakeup.visible = true
	family_group_dressing.visible = false
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(family_group, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(family_group_amulets, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(family_group_sleep, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(family_group_wakeup, "modulate:a", 1.0, 0.6)
	fade_tween.tween_property(family_group_dressing, "modulate:a", 0.0, 0.6)


func show_dressing_pose() -> void:
	_kill_fade_tween()
	_start_fire()
	background.texture = MORNING_BACKGROUND
	family_group.visible = true
	family_group_amulets.visible = true
	family_group_sleep.visible = true
	family_group_wakeup.visible = true
	family_group_dressing.visible = true
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(family_group, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(family_group_amulets, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(family_group_sleep, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(family_group_wakeup, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(family_group_dressing, "modulate:a", 1.0, 0.6)


## Мгновенная поза для Continue (без tween — иначе серый экран до завершения fade).
func apply_pose_instant(pose: String) -> void:
	_kill_fade_tween()
	match pose:
		"hidden":
			_set_character_layers_alpha(0.0)
			_stop_fire()
			visible = false
			return
		"day":
			_reset_to_initial_pose()
			_set_character_layers_alpha(1.0)
			family_group.modulate.a = 1.0
			bargyy.modulate.a = 1.0
			_start_fire()
		"amulets":
			_reset_to_initial_pose()
			family_group_amulets.visible = true
			family_group_amulets.modulate.a = 1.0
			family_group.modulate.a = 0.0
			bargyy.modulate.a = 1.0
			_start_fire()
		"sleep":
			_reset_to_initial_pose()
			family_group_amulets.visible = true
			family_group_sleep.visible = true
			family_group_sleep.modulate.a = 1.0
			family_group.modulate.a = 0.0
			family_group_amulets.modulate.a = 0.0
			bargyy.modulate.a = 1.0
			_start_fire()
		"wakeup":
			_start_fire()
			background.texture = MORNING_BACKGROUND
			family_group.visible = true
			family_group_amulets.visible = true
			family_group_sleep.visible = true
			family_group_wakeup.visible = true
			family_group_dressing.visible = false
			_set_character_layers_alpha(0.0)
			family_group_wakeup.modulate.a = 1.0
		"dressing":
			_start_fire()
			background.texture = MORNING_BACKGROUND
			family_group.visible = true
			family_group_amulets.visible = true
			family_group_sleep.visible = true
			family_group_wakeup.visible = true
			family_group_dressing.visible = true
			_set_character_layers_alpha(0.0)
			family_group_dressing.modulate.a = 1.0
		_:
			_reset_to_initial_pose()
			_set_character_layers_alpha(1.0)
			_start_fire()
	visible = pose != "hidden"


func hide_overlay() -> void:
	_stop_fire()
	if not visible:
		return

	_kill_fade_tween()
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(family_group, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(family_group_amulets, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(family_group_sleep, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(family_group_wakeup, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(family_group_dressing, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(bargyy, "modulate:a", 0.0, 0.6)
	fade_tween.set_parallel(false)
	fade_tween.tween_callback(_finish_hide)


func set_family_group_visible(value: bool) -> void:
	family_group.visible = value


func set_family_group_amulets_visible(value: bool) -> void:
	family_group_amulets.visible = value


func set_family_group_sleep_visible(value: bool) -> void:
	family_group_sleep.visible = value


func set_family_group_wakeup_visible(value: bool) -> void:
	family_group_wakeup.visible = value


func set_family_group_dressing_visible(value: bool) -> void:
	family_group_dressing.visible = value


func set_bargyy_visible(value: bool) -> void:
	bargyy.visible = value


func _finish_hide() -> void:
	visible = false


func _ensure_fire_nodes() -> bool:
	if fire_mask == null:
		fire_mask = get_node_or_null("FireMask") as Control
	if fire == null:
		fire = get_node_or_null("FireMask/Fire") as TextureRect
	return fire_mask != null and fire != null


func _setup_fire_frame_timer() -> void:
	if _fire_frame_timer != null:
		return
	_fire_frame_timer = Timer.new()
	_fire_frame_timer.wait_time = FIRE_FRAME_INTERVAL_SEC
	_fire_frame_timer.autostart = false
	_fire_frame_timer.one_shot = false
	_fire_frame_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	_fire_frame_timer.timeout.connect(_on_fire_frame_timeout)
	add_child(_fire_frame_timer)


func _start_fire() -> void:
	if not _ensure_fire_nodes():
		push_warning("START FIRE: FireMask/Fire nodes not found")
		return
	_setup_fire_frame_timer()

	var first_start := not _fire_effects_active
	_fire_effects_active = true

	if first_start:
		_fire_frame_index = 0
		fire.texture = FIRE_FRAMES[0]

	fire.modulate.a = FIRE_ALPHA_MIN
	fire.scale = Vector2.ONE
	fire_mask.visible = true
	fire.visible = true

	if _fire_frame_timer.is_stopped():
		_fire_frame_timer.start()


func _stop_fire() -> void:
	_fire_effects_active = false
	if _fire_frame_timer != null:
		_fire_frame_timer.stop()
	if fire != null:
		fire.visible = false
	if fire_mask != null:
		fire_mask.visible = false


func _on_fire_frame_timeout() -> void:
	if not _fire_effects_active or FIRE_FRAMES.is_empty():
		return
	if not _ensure_fire_nodes():
		return
	_fire_frame_index = (_fire_frame_index + 1) % FIRE_FRAMES.size()
	fire.texture = FIRE_FRAMES[_fire_frame_index]
	# Calm cooking-fire flicker: alpha 0.70..0.88, scale 0.97..1.00
	var pulse := float(_fire_frame_index) / float(max(1, FIRE_FRAMES.size() - 1))
	fire.modulate.a = lerpf(FIRE_ALPHA_MIN, FIRE_ALPHA_MAX, pulse)
	var scale_pulse := lerpf(FIRE_SCALE_MIN, FIRE_SCALE_MAX, 1.0 - pulse)
	fire.scale = Vector2(scale_pulse, scale_pulse)


func _set_character_layers_alpha(value: float) -> void:
	family_group.modulate.a = value
	family_group_amulets.modulate.a = value
	family_group_sleep.modulate.a = value
	family_group_wakeup.modulate.a = value
	family_group_dressing.modulate.a = value
	bargyy.modulate.a = value


func _reset_to_initial_pose() -> void:
	background.texture = DAY_BACKGROUND
	family_group.visible = true
	family_group_amulets.visible = false
	family_group_sleep.visible = false
	family_group_sleep.modulate.a = 0.0
	family_group_wakeup.visible = false
	family_group_wakeup.modulate.a = 0.0
	family_group_dressing.visible = false
	family_group_dressing.modulate.a = 0.0


func _kill_fade_tween() -> void:
	if fade_tween != null:
		fade_tween.kill()
		fade_tween = null
