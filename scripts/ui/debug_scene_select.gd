extends Control

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const MAIN_SCENE := "res://scenes/main.tscn"

const LESSON_ACT1_OPTIONS := [
	{"label": "lesson_act1: compassion", "value": "compassion"},
	{"label": "lesson_act1: boundaries", "value": "boundaries"},
	{"label": "lesson_act1: memory", "value": "memory"},
]

const LESSON_ACT2_OPTIONS := [
	{"label": "lesson_act2: acceptance", "value": "acceptance"},
	{"label": "lesson_act2: humility", "value": "humility"},
	{"label": "lesson_act2: strength", "value": "strength"},
]

const SCENES := [
	{"label": "Scene 1 — Пурга", "timeline": "scene1_timeline", "key": KEY_F1},
	{"label": "Scene 2 — Теневой бегун", "timeline": "scene2_timeline", "key": KEY_F2},
	{"label": "Scene 3 — Белая шаманка", "timeline": "scene3_timeline", "key": KEY_F3},
	{"label": "Scene 4", "timeline": "scene4_timeline", "key": KEY_F4},
	{"label": "Scene 5", "timeline": "scene5_timeline", "key": KEY_F5},
	{"label": "Scene 6", "timeline": "scene6_timeline", "key": KEY_F6},
	{"label": "Scene 7", "timeline": "scene7_timeline", "key": KEY_F7},
	{"label": "Scene 8", "timeline": "scene8_timeline", "key": KEY_F8},
	{"label": "Scene 9", "timeline": "scene9_timeline", "key": KEY_F9},
	{"label": "Scene 10 — Сердце Тьмы", "timeline": "scene10_timeline", "key": KEY_F10},
	{"label": "Bad ending — Ранний отказ", "timeline": "ending_bad_early", "key": 0},
]

var lesson_act1_select: OptionButton
var lesson_act2_select: OptionButton


func _ready() -> void:
	_add_lesson_controls()

	for scene_info in SCENES:
		var button := Button.new()
		button.text = scene_info["label"]
		button.custom_minimum_size = Vector2(320, 44)
		button.pressed.connect(_launch_timeline.bind(scene_info["timeline"]))
		%SceneGrid.add_child(button)

	%BackButton.pressed.connect(_on_back_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	for scene_info in SCENES:
		if scene_info["key"] != 0 and event.keycode == scene_info["key"]:
			_launch_timeline(scene_info["timeline"])
			get_viewport().set_input_as_handled()
			return


func _launch_timeline(timeline_name: String) -> void:
	_apply_selected_lessons()
	var debug_state: Variant = get_node_or_null("/root/DebugState")
	if debug_state != null:
		debug_state.set_start_timeline_override(timeline_name)
	get_tree().change_scene_to_file(MAIN_SCENE)


func _add_lesson_controls() -> void:
	var vbox := %SceneGrid.get_parent()
	var insert_index := %SceneGrid.get_index()

	var lesson_box := VBoxContainer.new()
	lesson_box.custom_minimum_size = Vector2(660, 0)
	lesson_box.add_theme_constant_override("separation", 8)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	lesson_act1_select = _create_lesson_select(LESSON_ACT1_OPTIONS)
	lesson_act2_select = _create_lesson_select(LESSON_ACT2_OPTIONS)
	row.add_child(lesson_act1_select)
	row.add_child(lesson_act2_select)
	lesson_box.add_child(row)

	var scene10_button := Button.new()
	scene10_button.text = "Start Scene 10 with selected lessons"
	scene10_button.custom_minimum_size = Vector2(660, 44)
	scene10_button.pressed.connect(_launch_timeline.bind("scene10_timeline"))
	lesson_box.add_child(scene10_button)

	vbox.add_child(lesson_box)
	vbox.move_child(lesson_box, insert_index)


func _create_lesson_select(options: Array) -> OptionButton:
	var select := OptionButton.new()
	select.custom_minimum_size = Vector2(324, 44)
	for option in options:
		var index := select.get_item_count()
		select.add_item(str(option["label"]))
		select.set_item_metadata(index, option["value"])
	select.select(0)
	return select


func _apply_selected_lessons() -> void:
	Dialogic.VAR.lesson_act1 = _selected_lesson_value(lesson_act1_select)
	Dialogic.VAR.lesson_act2 = _selected_lesson_value(lesson_act2_select)


func _selected_lesson_value(select: OptionButton) -> String:
	if select == null or select.selected < 0:
		return ""
	return str(select.get_item_metadata(select.selected))


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
