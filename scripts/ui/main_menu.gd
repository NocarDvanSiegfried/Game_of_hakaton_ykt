extends Control

const GAME_SCENE := "res://scenes/main.tscn"
const DEBUG_SCENE_SELECT_SCENE := "res://scenes/ui/debug_scene_select.tscn"
const DEBUG_SCENE_SELECT := true

@onready var menu_music: AudioStreamPlayer = $MenuMusic


func _ready() -> void:
	if not menu_music.playing:
		menu_music.play(0.0)
	%NewGameButton.pressed.connect(_on_new_game_pressed)
	%DebugSceneSelectButton.visible = DEBUG_SCENE_SELECT
	%DebugSceneSelectButton.pressed.connect(_on_debug_scene_select_pressed)
	%QuitButton.pressed.connect(_on_quit_pressed)


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_debug_scene_select_pressed() -> void:
	get_tree().change_scene_to_file(DEBUG_SCENE_SELECT_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
