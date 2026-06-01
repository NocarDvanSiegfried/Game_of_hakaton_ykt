extends Control

@onready var background: TextureRect = $Background
@onready var family_group: TextureRect = $FamilyGroup
@onready var bargyy: TextureRect = $Bargyy

var fade_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_character_layers_alpha(0.0)
	visible = false


func show_overlay() -> void:
	_kill_fade_tween()
	_set_character_layers_alpha(0.0)
	background.modulate.a = 1.0
	visible = true
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(family_group, "modulate:a", 1.0, 0.6)
	fade_tween.tween_property(bargyy, "modulate:a", 1.0, 0.6)


func hide_overlay() -> void:
	if not visible:
		return

	_kill_fade_tween()
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(family_group, "modulate:a", 0.0, 0.6)
	fade_tween.tween_property(bargyy, "modulate:a", 0.0, 0.6)
	fade_tween.set_parallel(false)
	fade_tween.tween_callback(_finish_hide)


func set_family_group_visible(value: bool) -> void:
	family_group.visible = value


func set_bargyy_visible(value: bool) -> void:
	bargyy.visible = value


func _finish_hide() -> void:
	visible = false


func _set_character_layers_alpha(value: float) -> void:
	family_group.modulate.a = value
	bargyy.modulate.a = value


func _kill_fade_tween() -> void:
	if fade_tween != null:
		fade_tween.kill()
		fade_tween = null
