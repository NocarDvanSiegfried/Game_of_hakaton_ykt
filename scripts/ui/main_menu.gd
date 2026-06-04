extends Control

const GAME_SCENE := "res://scenes/main.tscn"
const DEBUG_SCENE_SELECT_SCENE := "res://scenes/ui/debug_scene_select.tscn"
const DEBUG_SCENE_SELECT := true

@onready var menu_music: AudioStreamPlayer = $MenuMusic

var _settings_overlay: Control
var _confirm_overlay: Control


func _ready() -> void:
	if not menu_music.playing:
		menu_music.play(0.0)
	_refresh_continue_button()
	%ContinueButton.pressed.connect(_on_continue_pressed)
	%NewGameButton.pressed.connect(_on_new_game_pressed)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%DebugSceneSelectButton.visible = DEBUG_SCENE_SELECT
	%DebugSceneSelectButton.pressed.connect(_on_debug_scene_select_pressed)
	%QuitButton.pressed.connect(_on_quit_pressed)


func _refresh_continue_button() -> void:
	var has_save := GameSaveManager.has_autosave()
	%ContinueButton.visible = has_save
	%ContinueButton.disabled = not has_save


func _on_continue_pressed() -> void:
	if not GameSaveManager.has_autosave():
		return
	GameSession.request_continue()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_new_game_pressed() -> void:
	if GameSaveManager.has_autosave():
		_show_new_game_confirm()
		return
	_start_new_game()


func _show_new_game_confirm() -> void:
	if _confirm_overlay != null and is_instance_valid(_confirm_overlay):
		return
	_confirm_overlay = UiConfirmOverlay.open(
		self,
		"Новая игра",
		"Начать сначала? Текущий autosave будет удалён.",
		"Начать сначала",
		"Отмена"
	)
	_confirm_overlay.confirmed.connect(_on_new_game_confirmed)
	_confirm_overlay.cancelled.connect(_on_new_game_confirm_cancelled)


func _on_new_game_confirmed() -> void:
	_confirm_overlay = null
	GameSaveManager.delete_autosave()
	_start_new_game()


func _on_new_game_confirm_cancelled() -> void:
	_confirm_overlay = null


func _start_new_game() -> void:
	GameSession.request_new_game()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_settings_pressed() -> void:
	if _settings_overlay != null:
		return
	_settings_overlay = SettingsOverlayHelper.open(self, false)
	_settings_overlay.closed.connect(_on_settings_closed)


func _on_settings_closed() -> void:
	_settings_overlay = null


func _on_debug_scene_select_pressed() -> void:
	get_tree().change_scene_to_file(DEBUG_SCENE_SELECT_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
