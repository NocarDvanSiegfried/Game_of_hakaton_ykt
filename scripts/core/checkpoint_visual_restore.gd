extends Node
## Универсальное восстановление визуала по visual_state_id (не по конкретной сцене в коде).

const BG := {
	"intro_wasteland": "res://assets/art/backgrounds/scene_01/bg_scene1_intro_frozen_wasteland.png",
	"house_blizzard": "res://assets/art/backgrounds/scene_01/bg_scene1_house_window_blizzard.png",
	"house_blizzard2": "res://assets/art/backgrounds/scene_01/bg_scene1_house_window_blizzard2.jpg",
	"yard_tracks": "res://assets/art/backgrounds/scene_01/bg_scene1_dog_tracks_yard.jpg",
	"door_exit": "res://assets/art/backgrounds/scene_01/bg_scene1_house_door_exit.png",
	"forest_path": "res://assets/art/backgrounds/scene_01/snowy_forest_path.png",
	"ice_tunnel": "res://assets/art/backgrounds/scene_01/ice_tunnel.png",
	"black": "res://assets/art/черный.jpg",
}

const VISUAL_STATES := {
	"scene1_morning_wakeup": {
		"actions": [
			{"type": "dialogic_background", "path": BG.house_blizzard, "fade": 0.0},
			{"type": "scene1_overlay", "visible": true, "pose": "wakeup"},
		],
	},
	"scene1_yard_outdoor": {
		"actions": [
			{"type": "dialogic_background", "path": BG.yard_tracks, "fade": 0.0},
			{"type": "scene1_overlay", "visible": false},
		],
	},
	"scene1_forest_path": {
		"actions": [
			{"type": "dialogic_background", "path": BG.forest_path, "fade": 0.0},
			{"type": "scene1_overlay", "visible": false},
		],
	},
	"scene1_ice_hole": {
		"actions": [
			{"type": "dialogic_background", "path": BG.ice_tunnel, "fade": 0.0},
			{"type": "scene1_overlay", "visible": false},
		],
	},
	"chapter2_start": {
		"actions": [
			{"type": "dialogic_background", "path": BG.black, "fade": 0.0},
			{"type": "scene1_overlay", "visible": false},
		],
	},
	"chapter2_ice_tunnel": {
		"actions": [
			{"type": "dialogic_background", "path": BG.ice_tunnel, "fade": 0.0},
			{"type": "scene1_overlay", "visible": false},
		],
	},
	"chapter2_shadow_labyrinth": {
		"actions": [
			{"type": "dialogic_background", "path": BG.ice_tunnel, "fade": 0.0},
			{"type": "scene1_overlay", "visible": false},
		],
	},
	"chapter2_boss_arena": {
		"actions": [
			{"type": "dialogic_background", "path": BG.black, "fade": 0.0},
			{"type": "scene1_overlay", "visible": false},
		],
	},
	"dialogic_neutral_dark": {
		"actions": [
			{"type": "dialogic_background", "path": BG.black, "fade": 0.0},
			{"type": "scene1_overlay", "visible": false},
		],
	},
}


func get_visual_state_definition(visual_state_id: String) -> Dictionary:
	if visual_state_id in VISUAL_STATES:
		return VISUAL_STATES[visual_state_id]
	return VISUAL_STATES[GameCheckpointRegistry.FALLBACK_VISUAL_STATE]


func prepare_continue_session(main: Node) -> PackedStringArray:
	var cleared: PackedStringArray = []
	if main == null or not is_instance_valid(main):
		return cleared
	if main.has_method("clear_continue_transient_layers"):
		cleared = main.call("clear_continue_transient_layers")
	return cleared


func apply_visual_state_verified(
	visual_state_id: String,
	main: Node,
	dialogic_state: Dictionary = {}
) -> bool:
	if visual_state_id.is_empty():
		push_error("[VisualRestore VERIFY] visual_state_id пустой")
		return false

	if visual_state_id not in VISUAL_STATES:
		push_warning(
			"[VisualRestore VERIFY] неизвестный visual_state_id='%s', fallback" % visual_state_id
		)

	await _wait_background_holder(60)

	var saved_bg := str(dialogic_state.get("background_argument", ""))
	if saved_bg.is_empty() or not ResourceLoader.exists(saved_bg):
		saved_bg = _background_path_from_visual_state(visual_state_id)

	var applied := apply_visual_state(visual_state_id, main)
	if not applied:
		push_error("[VisualRestore VERIFY] apply_visual_state вернул false")
		return false

	if not saved_bg.is_empty() and Dialogic.has_subsystem("Backgrounds"):
		Dialogic.Backgrounds.update_background(
			"",
			saved_bg,
			0.0,
			Dialogic.Backgrounds.default_transition,
			true
		)
		print("[VisualRestore] background from autosave dialogic_state: %s" % saved_bg)

	var report := verify_visual_state(visual_state_id, main, saved_bg)
	print("[VisualRestore VERIFY] %s" % report.get("summary", ""))
	if not bool(report.get("ok", false)):
		for issue in report.get("issues", []):
			push_warning("[VisualRestore VERIFY] %s" % issue)
		if _background_has_valid_texture():
			print("[VisualRestore VERIFY] фон есть — Continue не блокируем")
			return true
		for issue in report.get("issues", []):
			push_error("[VisualRestore VERIFY] %s" % issue)
		return false

	print("[VisualRestore] applied visual_state_id=%s (verified)" % visual_state_id)
	return true


func apply_visual_state(visual_state_id: String, main: Node) -> bool:
	var def := get_visual_state_definition(visual_state_id)
	var actions: Array = def.get("actions", [])
	if actions.is_empty():
		push_warning("CheckpointVisualRestore: пустой visual_state '%s'" % visual_state_id)
		return false

	for action in actions:
		if typeof(action) != TYPE_DICTIONARY:
			continue
		if main != null and main.has_method("apply_visual_restore_action"):
			main.call("apply_visual_restore_action", action)
		else:
			_apply_action_fallback(action)

	return true


func _background_path_from_visual_state(visual_state_id: String) -> String:
	for action in get_visual_state_definition(visual_state_id).get("actions", []):
		if typeof(action) == TYPE_DICTIONARY and str(action.get("type", "")) == "dialogic_background":
			return str(action.get("path", ""))
	return ""


func _background_has_valid_texture() -> bool:
	var holder := _find_background_holder()
	if holder == null:
		return false
	var bg_node := _find_active_dialogic_background_node(holder)
	if bg_node == null:
		return false
	var image: TextureRect = bg_node.get_node_or_null("Image") as TextureRect
	return image != null and image.texture != null


func verify_visual_state(
	visual_state_id: String,
	main: Node,
	expected_background: String = ""
) -> Dictionary:
	var issues: PackedStringArray = []
	var def := get_visual_state_definition(visual_state_id)

	var bg_expected := expected_background
	if bg_expected.is_empty():
		bg_expected = _background_path_from_visual_state(visual_state_id)

	if not bg_expected.is_empty():
		issues.append_array(_verify_dialogic_background(bg_expected))

	for action in def.get("actions", []):
		if typeof(action) != TYPE_DICTIONARY:
			continue
		if str(action.get("type", "")) == "scene1_overlay":
			issues.append_array(_verify_scene1_overlay(main, action))

	var ok := issues.is_empty()
	var summary := "ok" if ok else "FAILED (%d issues)" % issues.size()
	return {"ok": ok, "issues": issues, "summary": summary}


func _verify_dialogic_background(expected_path: String) -> PackedStringArray:
	var issues: PackedStringArray = []
	if expected_path.is_empty():
		issues.append("background: expected path пустой")
		return issues

	if not ResourceLoader.exists(expected_path):
		issues.append("background: ресурс не существует %s" % expected_path)

	var holder := _find_background_holder()
	if holder == null:
		issues.append(
			"background: dialogic_background_holders не найден (серый экран = пустой DefaultBackground ColorRect)"
		)
		return issues

	var bg_node := _find_active_dialogic_background_node(holder)
	if bg_node == null:
		issues.append("background: нет активного DialogicBackground в holder")
		return issues

	var image: TextureRect = bg_node.get_node_or_null("Image") as TextureRect
	if image == null:
		issues.append("background: узел Image не найден в %s" % bg_node.get_path())
		return issues

	if image.texture == null:
		issues.append(
			"background: Image.texture=null на %s (серый слой — ColorRect под Image)" % image.get_path()
		)
		return issues

	var tex_path := ""
	if image.texture.resource_path:
		tex_path = image.texture.resource_path
	if tex_path != expected_path:
		issues.append("background: texture=%s ожидали %s" % [tex_path, expected_path])
	else:
		print(
			"[VisualRestore VERIFY] background OK path=%s visible=%s alpha=%s" % [
				tex_path,
				image.visible,
				image.modulate.a,
			]
		)

	return issues


func _verify_scene1_overlay(main: Node, action: Dictionary) -> PackedStringArray:
	var issues: PackedStringArray = []
	if main == null or not main.has_method("get_scene1_overlay_for_verify"):
		return issues

	var overlay: Control = main.call("get_scene1_overlay_for_verify") as Control
	var want_visible: bool = bool(action.get("visible", false))

	if want_visible:
		if overlay == null:
			issues.append("scene1_overlay: overlay=null, ожидали visible")
			return issues
		if not overlay.visible:
			issues.append("scene1_overlay: visible=false")
		if overlay.modulate.a < 0.01:
			issues.append("scene1_overlay: modulate.a≈0")
	else:
		if overlay != null and overlay.visible:
			issues.append("scene1_overlay: должен быть скрыт, но visible=true")

	return issues


func _find_active_dialogic_background_node(holder: Node) -> Node:
	for child in holder.get_children():
		if child.has_meta("node") and child.get_meta("node") is DialogicBackground:
			return child.get_meta("node") as Node
	return null


func _apply_dialogic_state_background_fallback(state: Dictionary) -> void:
	if state.is_empty():
		return
	var bg_arg := str(state.get("background_argument", ""))
	if bg_arg.is_empty() or not ResourceLoader.exists(bg_arg):
		return
	if not Dialogic.has_subsystem("Backgrounds"):
		return
	Dialogic.Backgrounds.update_background("", bg_arg, 0.0, Dialogic.Backgrounds.default_transition, true)
	print("[VisualRestore] fallback background from dialogic_state: %s" % bg_arg)


func _apply_action_fallback(action: Dictionary) -> void:
	if str(action.get("type", "")) != "dialogic_background":
		return
	var path: String = str(action.get("path", ""))
	if Dialogic.has_subsystem("Backgrounds") and not path.is_empty():
		Dialogic.Backgrounds.update_background(
			"",
			path,
			float(action.get("fade", 0.0)),
			Dialogic.Backgrounds.default_transition,
			true
		)


func _wait_background_holder(max_frames: int = 30) -> void:
	for _i in range(max_frames):
		if _find_background_holder() != null:
			return
		await Engine.get_main_loop().process_frame


func _find_background_holder() -> Node:
	if Dialogic.has_subsystem("Styles"):
		var holder: Node = Dialogic.Styles.get_first_node_in_layout("dialogic_background_holders")
		if holder != null:
			return holder
	return get_tree().get_first_node_in_group("dialogic_background_holders")
