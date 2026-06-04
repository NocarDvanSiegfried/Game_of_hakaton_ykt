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

var current_timeline := ""
var scene1_overlay: Control
var _settings_overlay: Control
var _settings_layer: CanvasLayer


func _ready() -> void:
	AudioSettings.apply_all()
	_settings_layer = CanvasLayer.new()
	_settings_layer.layer = 128
	add_child(_settings_layer)

	var timeline_ended_callback := Callable(self, "_on_timeline_ended")
	if not Dialogic.timeline_ended.is_connected(timeline_ended_callback):
		Dialogic.timeline_ended.connect(timeline_ended_callback)
	if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.connect(_on_dialogic_signal)

	# Имя timeline — это имя файла без расширения (.dtl).
	# Dialogic ищет таймлайны по всему проекту автоматически.
	var debug_state: Variant = get_node_or_null("/root/DebugState")
	var start_timeline := ""
	if debug_state != null:
		start_timeline = debug_state.consume_start_timeline_override()
	if start_timeline.is_empty():
		start_timeline = "scene1_timeline"
	else:
		debug_state.prepare_debug_vars_for_timeline(start_timeline)
	_start_timeline(start_timeline)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("game_open_settings"):
		return
	if _settings_overlay != null:
		return
	_open_in_game_settings()


func _open_in_game_settings() -> void:
	_settings_overlay = SettingsOverlayHelper.open(_settings_layer, true)
	_settings_overlay.closed.connect(_on_in_game_settings_closed)


func _on_in_game_settings_closed() -> void:
	_settings_overlay = null


func _start_timeline(timeline_name: String) -> void:
	current_timeline = timeline_name
	print("Запуск таймлайна: %s" % timeline_name)
	Dialogic.start(timeline_name)


func _on_dialogic_signal(argument: Variant) -> void:
	if argument == SCENE1_OVERLAY_SHOW_SIGNAL:
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
