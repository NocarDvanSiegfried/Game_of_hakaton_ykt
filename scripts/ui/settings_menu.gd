extends Control

signal closed

const SLIDER_MIN := 0
const SLIDER_MAX := 100
const SLIDER_STEP := 1

const _FONT := preload("res://assets/fonts/NotoSerif-Regular.ttf")

@onready var _sliders_container: VBoxContainer = %SlidersContainer
@onready var _hint_label: Label = %HintLabel

var _percent_labels: Dictionary = {}
var _sliders: Dictionary = {}
var _syncing_sliders := false
var _pause_dialogic := false


func set_dialogic_pause(enabled: bool) -> void:
	_pause_dialogic = enabled
	if enabled:
		Dialogic.paused = true


func _ready() -> void:
	_build_volume_rows()
	%ResetButton.pressed.connect(_on_reset_pressed)
	%BackButton.pressed.connect(_on_back_pressed)
	if _pause_dialogic:
		_hint_label.text = "Esc — закрыть · O — настройки в игре"
	call_deferred("_focus_first_slider")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("game_open_settings"):
		_close()
		get_viewport().set_input_as_handled()


func _build_volume_rows() -> void:
	for row in AudioSettings.UI_VOLUME_ROWS:
		var setting_key: String = row["key"]
		var label_text: String = row["label"]
		_sliders_container.add_child(_create_volume_row(setting_key, label_text))


func _create_volume_row(setting_key: String, label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(500, 36)

	var name_label := Label.new()
	name_label.text = label_text
	name_label.custom_minimum_size = Vector2(168, 0)
	name_label.add_theme_font_override("font", _FONT)
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.85, 1))
	row.add_child(name_label)

	var slider := HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = SLIDER_MIN
	slider.max_value = SLIDER_MAX
	slider.step = SLIDER_STEP
	slider.tick_count = 5
	slider.focus_mode = Control.FOCUS_ALL
	slider.value = AudioSettings.get_volume(setting_key) * SLIDER_MAX
	slider.value_changed.connect(_on_slider_value_changed.bind(setting_key))
	row.add_child(slider)
	_sliders[setting_key] = slider

	var percent_label := Label.new()
	percent_label.custom_minimum_size = Vector2(44, 0)
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	percent_label.add_theme_font_override("font", _FONT)
	percent_label.add_theme_font_size_override("font_size", 17)
	percent_label.add_theme_color_override("font_color", Color(0.82, 0.8, 0.74, 1))
	_update_percent_label(percent_label, slider.value)
	_percent_labels[setting_key] = percent_label
	row.add_child(percent_label)

	return row


func _on_slider_value_changed(value: float, setting_key: String) -> void:
	if _syncing_sliders:
		return
	AudioSettings.set_volume(setting_key, value / float(SLIDER_MAX))
	if _percent_labels.has(setting_key):
		_update_percent_label(_percent_labels[setting_key], value)


func _sync_sliders_from_settings() -> void:
	_syncing_sliders = true
	for setting_key in _sliders.keys():
		var slider: HSlider = _sliders[setting_key]
		var value := AudioSettings.get_volume(setting_key) * SLIDER_MAX
		slider.value = value
		if _percent_labels.has(setting_key):
			_update_percent_label(_percent_labels[setting_key], value)
	_syncing_sliders = false


func _update_percent_label(label: Label, slider_value: float) -> void:
	label.text = "%d%%" % int(round(slider_value))


func _on_reset_pressed() -> void:
	AudioSettings.reset_to_defaults()
	_sync_sliders_from_settings()


func _on_back_pressed() -> void:
	_close()


func _focus_first_slider() -> void:
	if _sliders.is_empty():
		return
	var first_key: String = AudioSettings.UI_VOLUME_ROWS[0]["key"]
	var slider: HSlider = _sliders.get(first_key)
	if slider != null:
		slider.grab_focus()


func _close() -> void:
	if _pause_dialogic:
		Dialogic.paused = false
	closed.emit()
	queue_free()
