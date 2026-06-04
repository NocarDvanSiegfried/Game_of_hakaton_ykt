extends Node

# Главный скрипт игры «Баргый: Путь сквозь Лёд»
# Запускает первый таймлайн (Сцена 1: Пурга) при старте проекта.

const SCENE1_OVERLAY_SHOW_SIGNAL := "show_scene1_grandmother_house_layered"
const SCENE1_OVERLAY_HIDE_SIGNAL := "hide_scene1_grandmother_house_layered"
const SCENE1_OVERLAY_AMULETS_SIGNAL := "show_scene1_amulets_pose"
const SCENE1_OVERLAY_SLEEP_SIGNAL := "show_scene1_sleep_pose"
const SCENE1_OVERLAY_WAKEUP_SIGNAL := "show_scene1_wakeup_pose"
const SCENE1_OVERLAY_DRESSING_SIGNAL := "show_scene1_dressing_pose"
const SCENE1_OVERLAY_SCENE: PackedScene = preload("res://scenes/overlays/scene1_grandmother_house_layered.tscn")

const CHAPTER_VIDEO_01_SIGNAL := "play_chapter_video_01"
const CHAPTER_VIDEO_PATH := "res://assets/video/chapter_01_blizzard.ogv"
const CHAPTER_VIDEO_STARTUP_FALLBACK_SEC := 4.0
const CHAPTER_VIDEO_MAX_PLAYBACK_SEC := 15.0
const CHAPTER_VIDEO_BUS := &"Music"
const CHAPTER_VIDEO_VOLUME_DB := -14.0

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const PAUSE_MENU_SCENE := preload("res://scenes/ui/in_game_pause_menu.tscn")

@onready var _chapter_video_layer: CanvasLayer = $ChapterVideoLayer
@onready var _chapter_video_player: VideoStreamPlayer = %ChapterVideoPlayer
@onready var _chapter_hint_label: Label = %ChapterHintLabel

var current_timeline := ""
var scene1_overlay: Control
var _settings_overlay: Control
var _settings_layer: CanvasLayer
var _pause_layer: CanvasLayer
var _pause_menu: Control
var _confirm_overlay: Control
var _game_paused := false
var _shutting_down := false

var _chapter_video_active := false
var _chapter_video_finishing := false
var _chapter_video_pause_set := false
var _chapter_max_timer_started := false
var _chapter_startup_timer: Timer
var _chapter_max_timer: Timer


func _ready() -> void:
	AudioSettings.apply_all()
	_setup_chapter_video_timers()
	_settings_layer = CanvasLayer.new()
	_settings_layer.layer = 128
	_settings_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_settings_layer)

	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 140
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)

	var timeline_ended_callback := Callable(self, "_on_timeline_ended")
	if not Dialogic.timeline_ended.is_connected(timeline_ended_callback):
		Dialogic.timeline_ended.connect(timeline_ended_callback)
	if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.connect(_on_dialogic_signal)

	var debug_state: Variant = get_node_or_null("/root/DebugState")
	var start_timeline := ""
	if debug_state != null:
		start_timeline = debug_state.consume_start_timeline_override()
	if start_timeline.is_empty():
		start_timeline = "scene1_timeline"
	else:
		debug_state.prepare_debug_vars_for_timeline(start_timeline)
	_start_timeline(start_timeline)


func _setup_chapter_video_timers() -> void:
	_chapter_startup_timer = Timer.new()
	_chapter_startup_timer.one_shot = true
	_chapter_startup_timer.wait_time = CHAPTER_VIDEO_STARTUP_FALLBACK_SEC
	_chapter_startup_timer.timeout.connect(_on_chapter_startup_fallback_timeout)
	add_child(_chapter_startup_timer)

	_chapter_max_timer = Timer.new()
	_chapter_max_timer.one_shot = true
	_chapter_max_timer.timeout.connect(_on_chapter_max_duration_timeout)
	add_child(_chapter_max_timer)


func _unhandled_input(event: InputEvent) -> void:
	if _shutting_down:
		return
	if not event.is_pressed() or event.is_echo():
		return

	if _chapter_video_active and not _chapter_video_finishing:
		if _is_chapter_skip_event(event):
			get_viewport().set_input_as_handled()
			_skip_chapter_video()
		return

	if _confirm_overlay != null and is_instance_valid(_confirm_overlay):
		return

	if _settings_overlay != null and is_instance_valid(_settings_overlay):
		return

	if _game_paused:
		if event.is_action_pressed("game_pause"):
			get_viewport().set_input_as_handled()
			_close_pause_menu()
		return

	if event.is_action_pressed("game_pause"):
		get_viewport().set_input_as_handled()
		_open_pause_menu()
		return

	if event.is_action_pressed("game_open_settings"):
		get_viewport().set_input_as_handled()
		_open_in_game_settings()


func _open_pause_menu() -> void:
	if _game_paused or _shutting_down:
		return

	_game_paused = true
	Dialogic.paused = true
	get_tree().paused = true

	_pause_menu = PAUSE_MENU_SCENE.instantiate() as Control
	_pause_layer.add_child(_pause_menu)
	_pause_menu.resume_requested.connect(_close_pause_menu)
	_pause_menu.settings_requested.connect(_on_pause_settings_pressed)
	_pause_menu.main_menu_requested.connect(_on_pause_main_menu_pressed)
	_pause_menu.quit_requested.connect(_on_pause_quit_pressed)


func _close_pause_menu() -> void:
	if not _game_paused:
		return

	_game_paused = false
	if _pause_menu != null and is_instance_valid(_pause_menu):
		_pause_menu.queue_free()
	_pause_menu = null

	get_tree().paused = false
	if not _chapter_video_pause_set:
		Dialogic.paused = false


func _open_in_game_settings() -> void:
	if _settings_overlay != null:
		return
	_settings_overlay = SettingsOverlayHelper.open(_settings_layer, true)
	_settings_overlay.closed.connect(_on_in_game_settings_closed)


func _on_pause_settings_pressed() -> void:
	if _settings_overlay != null:
		return
	_settings_overlay = SettingsOverlayHelper.open(
		_pause_layer,
		false,
		false,
		"Esc — назад · игра остаётся на паузе"
	)
	_settings_overlay.closed.connect(_on_in_game_settings_closed)


func _on_in_game_settings_closed() -> void:
	_settings_overlay = null


func _on_pause_main_menu_pressed() -> void:
	_show_confirm(
		"Главное меню",
		"Выйти в главное меню? Текущая сцена будет прервана.",
		"Выйти",
		_on_confirm_exit_to_main_menu
	)


func _on_pause_quit_pressed() -> void:
	_show_confirm(
		"Выход из игры",
		"Закрыть игру?",
		"Выйти",
		_on_confirm_quit_game
	)


func _show_confirm(title: String, message: String, confirm_text: String, on_confirm: Callable) -> void:
	if _confirm_overlay != null and is_instance_valid(_confirm_overlay):
		return
	_confirm_overlay = UiConfirmOverlay.open(_pause_layer, title, message, confirm_text, "Отмена")
	_confirm_overlay.confirmed.connect(func() -> void:
		_confirm_overlay = null
		on_confirm.call()
	)
	_confirm_overlay.cancelled.connect(func() -> void:
		_confirm_overlay = null
	)


func _on_confirm_exit_to_main_menu() -> void:
	await _shutdown_dialogic_session()
	if not is_inside_tree():
		return
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_confirm_quit_game() -> void:
	await _shutdown_dialogic_session()
	get_tree().quit()


func _shutdown_dialogic_session() -> void:
	_shutting_down = true
	_close_pause_menu()
	_close_settings_overlay()

	var timeline_ended_callback := Callable(self, "_on_timeline_ended")
	if Dialogic.timeline_ended.is_connected(timeline_ended_callback):
		Dialogic.timeline_ended.disconnect(timeline_ended_callback)

	_chapter_video_active = false
	_chapter_video_finishing = false
	_chapter_video_pause_set = false
	_stop_chapter_video_timers()
	if _chapter_video_player != null and _chapter_video_player.is_playing():
		_chapter_video_player.stop()
	if _chapter_video_layer != null:
		_chapter_video_layer.visible = false

	get_tree().paused = false
	Dialogic.paused = false

	if Dialogic.current_timeline != null:
		Dialogic.end_timeline(true)

	await get_tree().process_frame
	await get_tree().process_frame


func _close_settings_overlay() -> void:
	if _settings_overlay != null and is_instance_valid(_settings_overlay):
		_settings_overlay.queue_free()
	_settings_overlay = null


func _start_timeline(timeline_name: String) -> void:
	current_timeline = timeline_name
	print("Запуск таймлайна: %s" % timeline_name)
	Dialogic.start(timeline_name)


func _on_dialogic_signal(argument: Variant) -> void:
	if argument == CHAPTER_VIDEO_01_SIGNAL:
		_play_chapter_video_01()
	elif argument == SCENE1_OVERLAY_SHOW_SIGNAL:
		_show_scene1_overlay()
	elif argument == SCENE1_OVERLAY_HIDE_SIGNAL:
		_hide_scene1_overlay()
	elif argument == SCENE1_OVERLAY_AMULETS_SIGNAL:
		_show_scene1_amulets_pose()
	elif argument == SCENE1_OVERLAY_SLEEP_SIGNAL:
		_show_scene1_sleep_pose()
	elif argument == SCENE1_OVERLAY_WAKEUP_SIGNAL:
		_show_scene1_wakeup_pose()
	elif argument == SCENE1_OVERLAY_DRESSING_SIGNAL:
		_show_scene1_dressing_pose()


func _play_chapter_video_01() -> void:
	if _chapter_video_active or _chapter_video_finishing:
		return

	if not ResourceLoader.exists(CHAPTER_VIDEO_PATH):
		push_warning("Chapter video: файл не найден, продолжаем timeline: %s" % CHAPTER_VIDEO_PATH)
		return

	Dialogic.paused = true
	_chapter_video_pause_set = true
	_configure_chapter_video_audio()

	if not _try_start_chapter_video():
		_finish_chapter_video_and_resume_dialogic("видео не загрузилось")
		return

	_chapter_video_active = true
	_chapter_video_layer.visible = true
	_chapter_hint_label.visible = true
	_chapter_startup_timer.start()
	print("Глава 1 — Пурга: воспроизведение видео")


func _configure_chapter_video_audio() -> void:
	if AudioServer.get_bus_index(CHAPTER_VIDEO_BUS) >= 0:
		_chapter_video_player.bus = CHAPTER_VIDEO_BUS
	else:
		push_warning("Chapter video: bus '%s' не найден, оставляем Master." % CHAPTER_VIDEO_BUS)
	_chapter_video_player.volume_db = CHAPTER_VIDEO_VOLUME_DB


func _try_start_chapter_video() -> bool:
	if _chapter_video_player.finished.is_connected(_on_chapter_video_finished):
		_chapter_video_player.finished.disconnect(_on_chapter_video_finished)
	_chapter_video_player.finished.connect(_on_chapter_video_finished, CONNECT_ONE_SHOT)

	var stream: VideoStream = load(CHAPTER_VIDEO_PATH) as VideoStream
	if stream == null:
		var theora := VideoStreamTheora.new()
		theora.file = CHAPTER_VIDEO_PATH
		stream = theora

	if stream == null:
		return false

	_chapter_video_player.stream = stream
	_chapter_video_player.play()
	return true


func _process(_delta: float) -> void:
	if not _chapter_video_active or _chapter_video_finishing:
		return
	if not _chapter_video_player.is_playing():
		return

	if _chapter_startup_timer.time_left > 0.0:
		_chapter_startup_timer.stop()
		_start_chapter_max_duration_timer()


func _start_chapter_max_duration_timer() -> void:
	if _chapter_max_timer_started:
		return
	_chapter_max_timer_started = true
	_chapter_max_timer.wait_time = CHAPTER_VIDEO_MAX_PLAYBACK_SEC
	_chapter_max_timer.start()


func _is_chapter_skip_event(event: InputEvent) -> bool:
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


func _on_chapter_video_finished() -> void:
	_finish_chapter_video_and_resume_dialogic("видео завершено")


func _on_chapter_startup_fallback_timeout() -> void:
	if _chapter_video_player.is_playing():
		return
	_finish_chapter_video_and_resume_dialogic("таймаут запуска видео")


func _on_chapter_max_duration_timeout() -> void:
	_finish_chapter_video_and_resume_dialogic("максимальный таймаут воспроизведения")


func _skip_chapter_video() -> void:
	_finish_chapter_video_and_resume_dialogic("пропуск игроком")


func _finish_chapter_video_and_resume_dialogic(reason: String = "") -> void:
	if _chapter_video_finishing:
		return
	_chapter_video_finishing = true
	_chapter_video_active = false

	if not reason.is_empty():
		print("Глава 1 — Пурга → продолжение timeline (%s)" % reason)

	_stop_chapter_video_timers()
	if _chapter_video_player.is_playing():
		_chapter_video_player.stop()

	_chapter_video_layer.visible = false
	_chapter_hint_label.visible = false
	_chapter_max_timer_started = false

	if _chapter_video_pause_set:
		_chapter_video_pause_set = false
		Dialogic.paused = false

	_chapter_video_finishing = false


func _stop_chapter_video_timers() -> void:
	if _chapter_startup_timer != null:
		_chapter_startup_timer.stop()
	if _chapter_max_timer != null:
		_chapter_max_timer.stop()


func _show_scene1_overlay() -> void:
	var overlay := _ensure_scene1_overlay()
	if overlay != null and overlay.has_method("show_overlay"):
		overlay.call("show_overlay")


func _hide_scene1_overlay() -> void:
	if scene1_overlay != null and scene1_overlay.has_method("hide_overlay"):
		scene1_overlay.call("hide_overlay")


func _show_scene1_amulets_pose() -> void:
	var overlay := _ensure_scene1_overlay()
	if overlay != null and overlay.has_method("show_amulets_pose"):
		overlay.call("show_amulets_pose")


func _show_scene1_sleep_pose() -> void:
	var overlay := _ensure_scene1_overlay()
	if overlay != null and overlay.has_method("show_sleep_pose"):
		overlay.call("show_sleep_pose")


func _show_scene1_wakeup_pose() -> void:
	var overlay := _ensure_scene1_overlay()
	if overlay != null and overlay.has_method("show_wakeup_pose"):
		overlay.call("show_wakeup_pose")


func _show_scene1_dressing_pose() -> void:
	var overlay := _ensure_scene1_overlay()
	if overlay != null and overlay.has_method("show_dressing_pose"):
		overlay.call("show_dressing_pose")


func _ensure_scene1_overlay() -> Control:
	if scene1_overlay != null and is_instance_valid(scene1_overlay):
		return scene1_overlay

	var dialogic_layout := get_tree().get_meta("dialogic_layout_node", null) as Node
	if dialogic_layout == null:
		push_warning("Scene 1 overlay could not find Dialogic layout node.")
		return null

	scene1_overlay = SCENE1_OVERLAY_SCENE.instantiate() as Control
	dialogic_layout.add_child(scene1_overlay)
	dialogic_layout.move_child(scene1_overlay, _scene1_overlay_layer_index(dialogic_layout))
	return scene1_overlay


func _scene1_overlay_layer_index(dialogic_layout: Node) -> int:
	for index in range(dialogic_layout.get_child_count()):
		if dialogic_layout.get_child(index).name == "BackgroundLayer":
			return min(index + 1, dialogic_layout.get_child_count() - 1)

	return 0


func _on_timeline_ended() -> void:
	if _shutting_down:
		return
	print("Завершён таймлайн: ", current_timeline)
	match current_timeline:
		"scene1_timeline":
			await get_tree().process_frame
			_start_timeline("scene2_timeline")
		"scene2_timeline":
			await get_tree().process_frame
			_start_timeline("scene3_timeline")
		"scene3_timeline":
			print("accepted_initiation = ", Dialogic.VAR.accepted_initiation)
			if Dialogic.VAR.accepted_initiation == false:
				print("Концовка достигнута: ранний отказ от инициаций")
				await get_tree().process_frame
				_start_timeline("ending_bad_early")
				return
			await get_tree().process_frame
			_start_timeline("scene4_timeline")
		"scene4_timeline":
			await get_tree().process_frame
			_start_timeline("scene5_timeline")
		"scene5_timeline":
			await get_tree().process_frame
			_start_timeline("scene6_timeline")
		"scene6_timeline":
			await get_tree().process_frame
			_start_timeline("scene7_timeline")
		"scene7_timeline":
			await get_tree().process_frame
			_start_timeline("scene8_timeline")
		"scene8_timeline":
			await get_tree().process_frame
			_start_timeline("scene9_timeline")
		"scene9_timeline":
			await get_tree().process_frame
			_start_timeline("scene10_timeline")
		"scene10_timeline":
			var ending_value: Variant = Dialogic.VAR.ending_id
			var eid := 5
			if typeof(ending_value) == TYPE_INT or typeof(ending_value) == TYPE_FLOAT:
				eid = int(ending_value)
			else:
				var ending_text := str(ending_value)
				if ending_text.is_valid_int():
					eid = ending_text.to_int()
			if eid < 1 or eid > 9:
				eid = 5
			await get_tree().process_frame
			_start_timeline("scene10_ending_%d" % eid)
		"scene10_ending_1":
			print("Игра завершена. Концовка 1.")
		"scene10_ending_2":
			print("Игра завершена. Концовка 2.")
		"scene10_ending_3":
			print("Игра завершена. Концовка 3.")
		"scene10_ending_4":
			print("Игра завершена. Концовка 4.")
		"scene10_ending_5":
			print("Игра завершена. Концовка 5.")
		"scene10_ending_6":
			print("Игра завершена. Концовка 6.")
		"scene10_ending_7":
			print("Игра завершена. Концовка 7.")
		"scene10_ending_8":
			print("Игра завершена. Концовка 8.")
		"scene10_ending_9":
			print("Игра завершена. Концовка 9.")
		"ending_bad_early":
			print("Игра завершена. Ранняя плохая концовка пройдена.")
		_:
			print("Таймлайн завершён: %s" % current_timeline)
