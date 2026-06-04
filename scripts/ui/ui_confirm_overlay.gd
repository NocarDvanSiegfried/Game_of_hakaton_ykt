class_name UiConfirmOverlay
extends Control
## Диалог подтверждения поверх паузы (process_mode ALWAYS).

signal confirmed
signal cancelled

const SCENE := preload("res://scenes/ui/ui_confirm_overlay.tscn")


static func open(
	parent: Node,
	title: String,
	message: String,
	confirm_text: String = "Да",
	cancel_text: String = "Отмена"
) -> Control:
	var overlay := SCENE.instantiate() as Control
	parent.add_child(overlay)
	if overlay.has_method("setup"):
		overlay.call("setup", title, message, confirm_text, cancel_text)
	return overlay


func setup(title: String, message: String, confirm_text: String, cancel_text: String) -> void:
	%TitleLabel.text = title
	%MessageLabel.text = message
	%ConfirmButton.text = confirm_text
	%CancelButton.text = cancel_text


func _ready() -> void:
	%ConfirmButton.pressed.connect(_on_confirm_pressed)
	%CancelButton.pressed.connect(_on_cancel_pressed)
	call_deferred("_focus_confirm")


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_cancelled()


func _on_confirm_pressed() -> void:
	confirmed.emit()
	queue_free()


func _on_cancel_pressed() -> void:
	_close_cancelled()


func _close_cancelled() -> void:
	cancelled.emit()
	queue_free()


func _focus_confirm() -> void:
	%ConfirmButton.grab_focus()
