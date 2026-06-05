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
const SCENE1_BLIZZARD_LIGHT_SHOW_SIGNAL := "show_scene1_blizzard_light"
const SCENE1_BLIZZARD_LIGHT_HIDE_SIGNAL := "hide_scene1_blizzard_light"
const SCENE1_BLIZZARD_LIGHT_SCENE: PackedScene = preload("res://scenes/overlays/scene1_blizzard_light_overlay.tscn")

const CHAPTER_VIDEO_01_SIGNAL := "play_chapter_video_01"
const SCENE1_PART2_LABEL := "scene1_part2_morning"
const SCENE2_INTRO_LABEL := "scene2_chapter2_intro"
const CHAPTER2_ENTRY_REASON := "chapter2_entry"
const CHECKPOINT_SIGNAL_PREFIX := "checkpoint_"
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
var blizzard_light_overlay: Control
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

## Диагностика: момент Continue в scene1 (для детекта мгновенного scene1→scene2).
var _continue_scene1_start_msec := -1
## Истина: финал scene1_timeline пройден (сигнал checkpoint_chapter2_entry).
var _chapter1_story_finished := false


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
	if not start_timeline.is_empty():
		debug_state.prepare_debug_vars_for_timeline(start_timeline)
		_start_timeline(start_timeline)
		return

	if GameSession.consume_start_mode() == GameSession.StartMode.CONTINUE:
		print("[Main] Continue pipeline=dialogic_start_then_visual_restore (Backgrounds subsystem)")
		_continue_from_autosave_flow()
		return

	_chapter1_story_finished = false
	_start_timeline("scene1_timeline")


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
	if _chapter1_story_finished:
		_save_chapter2_entry_checkpoint("exit_main_menu")
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


func _continue_from_autosave_flow() -> void:
	GameSaveManager.log_autosave_contents("before Continue")

	var data := GameSaveManager.load_autosave()
	if data.is_empty():
		push_warning("Continue: autosave не найден, начинаем новую игру.")
		_start_timeline("scene1_timeline")
		return

	var timeline: String = str(data.get("timeline", "scene1_timeline"))
	var label: String = str(data.get("label", ""))
	var checkpoint_id: String = str(data.get("checkpoint_id", data.get("reason", "")))
	var state: Dictionary = data.get("dialogic_state", {})

	current_timeline = timeline
	print(
		"[Continue] checkpoint_id=%s visual_state_id=%s save_version=%s ch=%d order=%d timeline=%s label=%s" % [
			checkpoint_id,
			data.get("visual_state_id", ""),
			data.get("version", 0),
			data.get("chapter_index", 0),
			data.get("checkpoint_order", 0),
			timeline,
			label,
		]
	)

	if timeline == "scene1_timeline":
		_continue_scene1_start_msec = Time.get_ticks_msec()

	var visual_state_id := str(data.get("visual_state_id", ""))
	if visual_state_id.is_empty():
		visual_state_id = GameCheckpointRegistry.get_visual_state_id(checkpoint_id)

	print(
		"[Continue] visual_state_id=%s save_version=%s reason=%s" % [
			visual_state_id,
			data.get("version", 0),
			data.get("reason", ""),
		]
	)

	var cleared: PackedStringArray = CheckpointVisualRestore.prepare_continue_session(self)
	if cleared.size() > 0:
		print("[Continue] cleared overlays: %s" % ", ".join(cleared))

	_apply_dialogic_variables_from_state(state)

	if not label.is_empty():
		if not _timeline_has_label(timeline, label):
			push_error("[Continue FAIL] label '%s' не найден в %s" % [label, timeline])
			return
		await _continue_start_dialogic_then_restore(timeline, label, visual_state_id, state)
		return

	if not state.is_empty():
		print("[Dialogic LOAD_STATE] timeline=%s checkpoint_id=%s" % [timeline, checkpoint_id])
		Dialogic.load_full_state(state)
		await get_tree().process_frame
		await CheckpointVisualRestore.apply_visual_state_verified(visual_state_id, self, state)
		call_deferred("_diag_dialogic_position", "after Continue load_full_state")
		return

	await _continue_start_dialogic_then_restore(timeline, "", visual_state_id, state)


func _continue_start_dialogic_then_restore(
	timeline: String,
	label: String,
	visual_state_id: String,
	dialogic_state: Dictionary
) -> void:
	print("[Dialogic START] timeline=%s label=%s (before visual re-apply)" % [timeline, label])
	current_timeline = timeline

	var layout: Node = null
	if label.is_empty():
		layout = Dialogic.start(timeline)
	else:
		layout = Dialogic.start(timeline, label)

	if layout != null and not layout.is_node_ready():
		await layout.ready
	await get_tree().process_frame
	await get_tree().process_frame

	var restore_ok: bool = await CheckpointVisualRestore.apply_visual_state_verified(
		visual_state_id,
		self,
		dialogic_state
	)
	if not restore_ok:
		push_warning(
			"[Continue] visual_state '%s' verify не идеален — игра продолжается" % visual_state_id
		)
	call_deferred("_diag_dialogic_position", "after Continue visual re-apply")


func clear_continue_transient_layers() -> PackedStringArray:
	var cleared: PackedStringArray = []

	_game_paused = false
	get_tree().paused = false
	Dialogic.paused = false
	_chapter_video_pause_set = false

	if _pause_menu != null and is_instance_valid(_pause_menu):
		_pause_menu.queue_free()
		_pause_menu = null
		cleared.append("pause_menu")

	_close_settings_overlay()
	cleared.append("settings_overlay")

	if _confirm_overlay != null and is_instance_valid(_confirm_overlay):
		_confirm_overlay.queue_free()
		_confirm_overlay = null
		cleared.append("confirm_overlay")

	_chapter_video_active = false
	_chapter_video_finishing = false
	_stop_chapter_video_timers()
	if _chapter_video_player != null and _chapter_video_player.is_playing():
		_chapter_video_player.stop()
	if _chapter_video_layer != null:
		_chapter_video_layer.visible = false
		cleared.append("chapter_video_layer")

	if scene1_overlay != null and is_instance_valid(scene1_overlay):
		if scene1_overlay.has_method("apply_pose_instant"):
			scene1_overlay.call("apply_pose_instant", "hidden")

	if blizzard_light_overlay != null and is_instance_valid(blizzard_light_overlay):
		if blizzard_light_overlay.has_method("stop_flicker"):
			blizzard_light_overlay.call("stop_flicker")

	return cleared


func apply_visual_restore_action(action: Dictionary) -> void:
	if action.is_empty():
		return

	match str(action.get("type", "")):
		"dialogic_background":
			var path: String = str(action.get("path", ""))
			if path.is_empty():
				push_warning("dialogic_background: пустой path")
				return
			if not Dialogic.has_subsystem("Backgrounds"):
				push_error("dialogic_background: подсистема Dialogic.Backgrounds отсутствует")
				return
			if not ResourceLoader.exists(path):
				push_error("dialogic_background: ресурс не найден: %s" % path)
				return
			Dialogic.Backgrounds.update_background(
				"",
				path,
				float(action.get("fade", 0.0)),
				Dialogic.Backgrounds.default_transition,
				true
			)
			print("[VisualRestore] dialogic_background → %s" % path)
		"scene1_overlay":
			var overlay := _ensure_scene1_overlay()
			if overlay == null:
				return
			var visible: bool = bool(action.get("visible", false))
			if not visible:
				if overlay.has_method("apply_pose_instant"):
					overlay.call("apply_pose_instant", "hidden")
				elif overlay.has_method("hide_overlay"):
					overlay.call("hide_overlay")
				return
			var pose: String = str(action.get("pose", "day"))
			if overlay.has_method("apply_pose_instant"):
				overlay.call("apply_pose_instant", pose)
			elif overlay.has_method("show_overlay"):
				overlay.call("show_overlay")
		_:
			push_warning("apply_visual_restore_action: неизвестный type '%s'" % action.get("type", ""))


func _apply_dialogic_variables_from_state(state: Dictionary) -> void:
	if state.is_empty() or not state.has("variables"):
		return
	if Dialogic.current_state_info.is_empty():
		Dialogic.current_state_info = {}
	Dialogic.current_state_info["variables"] = state["variables"].duplicate(true)


func _start_timeline(timeline_name: String, label: String = "") -> void:
	current_timeline = timeline_name
	if label.is_empty():
		print("[Dialogic START] timeline=%s label=(начало)" % timeline_name)
		Dialogic.start(timeline_name)
	else:
		print("[Dialogic START] timeline=%s label=%s" % [timeline_name, label])
		Dialogic.start(timeline_name, label)
	call_deferred("_diag_dialogic_position", "after _start_timeline")


func _run_safe_checkpoint_save(timeline: String, label: String, reason: String) -> void:
	if _shutting_down:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if _shutting_down or not is_inside_tree() or Dialogic.current_timeline == null:
		return

	var state := Dialogic.get_full_state()
	GameSaveManager.save_checkpoint(timeline, label, state, reason)


func _persist_checkpoint_after_chapter_video() -> void:
	await _run_safe_checkpoint_save(
		"scene1_timeline",
		SCENE1_PART2_LABEL,
		"scene1_after_video_morning"
	)
	if is_inside_tree():
		GameSaveManager.log_autosave_contents("after chapter video checkpoint")


func _save_chapter2_entry_checkpoint(source: String) -> bool:
	var state := {}
	if Dialogic.current_timeline != null and not _shutting_down:
		state = Dialogic.get_full_state()

	var ok := GameSaveManager.save_checkpoint(
		"scene2_timeline",
		"",
		state,
		CHAPTER2_ENTRY_REASON
	)
	print("[ChapterTransition] chapter2_entry source=%s saved=%s" % [source, ok])
	return ok


func _on_chapter2_entry_checkpoint_signal() -> void:
	_chapter1_story_finished = true
	_save_chapter2_entry_checkpoint("scene1_final_signal")


func _persist_checkpoint_from_signal(signal_name: String) -> void:
	var reason := GameSaveManager.signal_to_reason(signal_name)
	if reason.is_empty():
		push_warning("Checkpoint: неизвестный signal '%s'" % signal_name)
		return

	if reason == CHAPTER2_ENTRY_REASON:
		_on_chapter2_entry_checkpoint_signal()
		return

	var def := GameSaveManager.get_checkpoint_definition(reason)
	if def.is_empty():
		push_warning("Checkpoint: нет определения для reason '%s'" % reason)
		return

	await _run_safe_checkpoint_save(
		str(def.get("timeline", "")),
		str(def.get("label", "")),
		reason
	)


func _on_dialogic_signal(argument: Variant) -> void:
	var arg_str := str(argument)
	if arg_str.begins_with(CHECKPOINT_SIGNAL_PREFIX):
		_persist_checkpoint_from_signal(arg_str)
		return
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
	elif argument == SCENE1_BLIZZARD_LIGHT_SHOW_SIGNAL:
		_show_scene1_blizzard_light()
	elif argument == SCENE1_BLIZZARD_LIGHT_HIDE_SIGNAL:
		_hide_scene1_blizzard_light()


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
	call_deferred("_persist_checkpoint_after_chapter_video")


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


func _show_scene1_blizzard_light() -> void:
	var overlay := _ensure_scene1_blizzard_light_overlay()
	if overlay != null and overlay.has_method("start_flicker"):
		overlay.call("start_flicker")


func _hide_scene1_blizzard_light() -> void:
	if blizzard_light_overlay != null and blizzard_light_overlay.has_method("stop_flicker"):
		blizzard_light_overlay.call("stop_flicker")


func get_scene1_overlay_for_verify() -> Control:
	if scene1_overlay != null and is_instance_valid(scene1_overlay):
		return scene1_overlay
	var layout := get_tree().get_meta("dialogic_layout_node", null) as Node
	if layout == null:
		return null
	return layout.find_child("Scene1GrandmotherHouseLayered", true, false) as Control


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


func _ensure_scene1_blizzard_light_overlay() -> Control:
	if blizzard_light_overlay != null and is_instance_valid(blizzard_light_overlay):
		return blizzard_light_overlay

	var dialogic_layout := get_tree().get_meta("dialogic_layout_node", null) as Node
	if dialogic_layout == null:
		push_warning("Scene 1 blizzard light overlay could not find Dialogic layout node.")
		return null

	blizzard_light_overlay = SCENE1_BLIZZARD_LIGHT_SCENE.instantiate() as Control
	dialogic_layout.add_child(blizzard_light_overlay)
	dialogic_layout.move_child(blizzard_light_overlay, _scene1_overlay_layer_index(dialogic_layout))
	return blizzard_light_overlay


func _scene1_overlay_layer_index(dialogic_layout: Node) -> int:
	for index in range(dialogic_layout.get_child_count()):
		if dialogic_layout.get_child(index).name == "BackgroundLayer":
			return min(index + 1, dialogic_layout.get_child_count() - 1)

	return 0


func _timeline_has_label(timeline_name: String, label_name: String) -> bool:
	var timeline_res: DialogicTimeline = DialogicResourceUtil.get_timeline_resource(timeline_name)
	if timeline_res == null:
		return false
	timeline_res.process()
	for event in timeline_res.events:
		if event is DialogicLabelEvent and event.name == label_name:
			return true
	return false


func _diag_dialogic_position(context: String) -> void:
	if Dialogic.current_timeline == null:
		print("[Dialogic DIAG:%s] timeline ещё не загружен" % context)
		return

	var timeline_id := ""
	if Dialogic.current_timeline.has_method("get_identifier"):
		timeline_id = Dialogic.current_timeline.get_identifier()
	if timeline_id.is_empty():
		timeline_id = current_timeline

	var next_idx := Dialogic.current_event_idx + 1
	var next_event: Variant = Dialogic.current_timeline.get_event(next_idx)
	var next_desc := "(конец timeline)"
	if next_event != null:
		if next_event is DialogicLabelEvent:
			next_desc = "Label '%s'" % next_event.name
		elif next_event is DialogicEvent:
			next_desc = "%s: %s" % [next_event.event_name, str(next_event.event_node_as_text).substr(0, 60)]
		else:
			next_desc = str(next_event).substr(0, 60)

	var last_label := ""
	if Dialogic.has_subsystem("Jump"):
		last_label = Dialogic.Jump.get_last_label_identifier()

	print(
		"[Dialogic DIAG:%s] timeline=%s event_idx=%d next[%d]=%s last_label=%s" % [
			context,
			timeline_id,
			Dialogic.current_event_idx,
			next_idx,
			next_desc,
			last_label,
		]
	)


func _on_timeline_ended() -> void:
	if _shutting_down:
		return

	var ended := current_timeline
	print("[Timeline ENDED] current_timeline=%s" % ended)

	match ended:
		"scene1_timeline":
			if _continue_scene1_start_msec >= 0:
				var elapsed_ms := Time.get_ticks_msec() - _continue_scene1_start_msec
				_continue_scene1_start_msec = -1
				if elapsed_ms < 800:
					push_warning(
						"[ДИАГНОСТИКА] scene1→scene2 сразу после Continue (~%d ms). "
						+ "Проверьте label в .dtl (должно быть: label имя, не [label name=...])." % elapsed_ms
					)
			_chapter1_story_finished = true
			if not _save_chapter2_entry_checkpoint("timeline_ended_fallback"):
				push_warning("[ChapterTransition] не удалось записать chapter2_entry при end_timeline")
			print("[Timeline CHAIN] scene1_timeline ended → scene2_timeline (без раннего autosave)")
			await get_tree().process_frame
			_start_timeline("scene2_timeline")
		"scene2_timeline":
			print("[Timeline CHAIN] scene2_timeline ended → scene3_timeline")
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
