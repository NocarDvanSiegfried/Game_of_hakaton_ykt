extends Control
## Вступительная видеозаставка перед главным меню.

const NEXT_SCENE := "res://scenes/ui/main_menu.tscn"
const INTRO_VIDEO_PATH := "res://assets/video/intro.ogv"

## Если видео не начало воспроизведение — переходим в меню.
const STARTUP_FALLBACK_SEC := 4.0
## Запасной таймаут, если сигнал finished не сработал.
const MAX_PLAYBACK_SEC := 180.0

@onready var _video_player: VideoStreamPlayer = %VideoPlayer
@onready var _hint_label: Label = %HintLabel

var _is_transitioning := false
var _max_duration_timer_started := false
var _startup_fallback_timer: Timer
var _max_duration_timer: Timer


func _ready() -> void:
	_setup_timers()
	_video_player.finished.connect(_on_video_finished)

	if not _try_start_video():
		_go_to_next_scene("видео не найдено или не загрузилось")
		return

	_startup_fallback_timer.start()
	_show_skip_hint()


func _setup_timers() -> void:
	_startup_fallback_timer = Timer.new()
	_startup_fallback_timer.one_shot = true
	_startup_fallback_timer.wait_time = STARTUP_FALLBACK_SEC
	_startup_fallback_timer.timeout.connect(_on_startup_fallback_timeout)
	add_child(_startup_fallback_timer)

	_max_duration_timer = Timer.new()
	_max_duration_timer.one_shot = true
	_max_duration_timer.timeout.connect(_on_max_duration_timeout)
	add_child(_max_duration_timer)


func _try_start_video() -> bool:
	if not ResourceLoader.exists(INTRO_VIDEO_PATH):
		push_warning("Intro: файл не найден: %s" % INTRO_VIDEO_PATH)
		return false

	var stream: VideoStream = load(INTRO_VIDEO_PATH) as VideoStream
	if stream == null:
		var theora := VideoStreamTheora.new()
		theora.file = INTRO_VIDEO_PATH
		stream = theora

	if stream == null:
		push_warning("Intro: не удалось создать VideoStream для %s" % INTRO_VIDEO_PATH)
		return false

	_video_player.stream = stream
	_video_player.play()
	return true


func _process(_delta: float) -> void:
	if _is_transitioning:
		return
	if not _video_player.is_playing():
		return

	if _startup_fallback_timer.time_left > 0.0:
		_startup_fallback_timer.stop()
		_start_max_duration_timer()


func _start_max_duration_timer() -> void:
	if _max_duration_timer_started:
		return
	_max_duration_timer_started = true

	# VideoStreamTheora / VideoStreamPlayer в 4.6 не дают длительность ролика.
	# Запасной таймер на случай, если finished не сработает.
	_max_duration_timer.wait_time = MAX_PLAYBACK_SEC
	_max_duration_timer.start()


func _input(event: InputEvent) -> void:
	if _is_transitioning or not is_inside_tree():
		return
	if not _is_skip_event(event):
		return
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()
	_skip_intro()


func _is_skip_event(event: InputEvent) -> bool:
	if not event.is_pressed() or event.is_echo():
		return false

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		return true

	if event is InputEventKey:
		var key_event := event as InputEventKey
		return key_event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.button_index == MOUSE_BUTTON_LEFT

	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed

	return false


func _on_video_finished() -> void:
	_go_to_next_scene("видео завершено")


func _on_startup_fallback_timeout() -> void:
	if _video_player.is_playing():
		return
	_go_to_next_scene("таймаут запуска видео")


func _on_max_duration_timeout() -> void:
	_go_to_next_scene("максимальный таймаут воспроизведения")


func _skip_intro() -> void:
	_go_to_next_scene("пропуск игроком")


func _show_skip_hint() -> void:
	_hint_label.text = "Enter · Space · Esc · ЛКМ — пропустить"
	_hint_label.visible = true


func _go_to_next_scene(reason: String = "") -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	if not reason.is_empty():
		print("Intro → главное меню (%s)" % reason)

	_stop_timers()
	if _video_player.is_playing():
		_video_player.stop()

	get_tree().change_scene_to_file(NEXT_SCENE)


func _stop_timers() -> void:
	if _startup_fallback_timer != null:
		_startup_fallback_timer.stop()
	if _max_duration_timer != null:
		_max_duration_timer.stop()
