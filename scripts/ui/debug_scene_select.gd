extends Control

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const MAIN_SCENE := "res://scenes/main.tscn"

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


func _ready() -> void:
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
	var debug_state: Variant = get_node_or_null("/root/DebugState")
	if debug_state != null:
		debug_state.set_start_timeline_override(timeline_name)
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
