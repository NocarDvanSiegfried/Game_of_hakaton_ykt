extends CanvasLayer

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const DISPLAY_TIME_SEC := 3.5

@onready var message: Label = %Message


func _ready() -> void:
	message.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(message, "modulate:a", 1.0, 0.8)

	await get_tree().create_timer(DISPLAY_TIME_SEC).timeout
	var tree := get_tree()
	queue_free()
	tree.change_scene_to_file(MAIN_MENU)
