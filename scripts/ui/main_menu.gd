extends Control

const GAME_SCENE := "res://scenes/main.tscn"


func _ready() -> void:
	%NewGameButton.pressed.connect(_on_new_game_pressed)
	%QuitButton.pressed.connect(_on_quit_pressed)


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
