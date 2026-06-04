extends Node
## Autosave: прогресс (глава/сцена/order) + checkpoint_id + visual_state_id для восстановления картинки.

const AUTOSAVE_PATH := "user://bargyy_autosave.json"
const SAVE_VERSION := 3

const VALID_TIMELINES := [
	"scene1_timeline",
	"scene2_timeline",
	"scene3_timeline",
	"scene4_timeline",
	"scene5_timeline",
	"scene6_timeline",
	"scene7_timeline",
	"scene8_timeline",
	"scene9_timeline",
	"scene10_timeline",
	"scene10_ending_1",
	"scene10_ending_2",
	"scene10_ending_3",
	"scene10_ending_4",
	"scene10_ending_5",
	"scene10_ending_6",
	"scene10_ending_7",
	"scene10_ending_8",
	"scene10_ending_9",
	"ending_bad_early",
]


func has_autosave() -> bool:
	return not load_autosave().is_empty()


func delete_autosave() -> void:
	if FileAccess.file_exists(AUTOSAVE_PATH):
		DirAccess.remove_absolute(AUTOSAVE_PATH)


func signal_to_reason(signal_name: String) -> String:
	return GameCheckpointRegistry.signal_to_reason(signal_name)


func get_checkpoint_definition(reason: String) -> Dictionary:
	return GameCheckpointRegistry.get_definition(reason)


func get_reason_priority(reason: String) -> int:
	var def := get_checkpoint_definition(reason)
	return int(def.get("priority", 0))


func progress_from_data(data: Dictionary) -> Vector3i:
	return Vector3i(
		int(data.get("chapter_index", 0)),
		int(data.get("scene_index", 0)),
		int(data.get("checkpoint_order", 0)),
	)


func is_progress_ahead(new_progress: Vector3i, old_progress: Vector3i) -> bool:
	if new_progress.x > old_progress.x:
		return true
	if new_progress.x < old_progress.x:
		return false
	if new_progress.y > old_progress.y:
		return true
	if new_progress.y < old_progress.y:
		return false
	return new_progress.z > old_progress.z


func should_overwrite_checkpoint(existing: Dictionary, new_meta: Dictionary) -> bool:
	if existing.is_empty():
		return true

	var old_progress := progress_from_data(existing)
	var new_progress := progress_from_data(new_meta)

	if is_progress_ahead(new_progress, old_progress):
		return true
	if new_progress != old_progress:
		print(
			"[Autosave SKIP] '%s' позади '%s' (progress %s < %s)" % [
				new_meta.get("reason", ""),
				existing.get("reason", ""),
				new_progress,
				old_progress,
			]
		)
		return false

	var new_priority := int(new_meta.get("priority", 0))
	var old_priority := int(existing.get("priority", 0))
	if new_priority < old_priority:
		print(
			"[Autosave SKIP] '%s' priority %d < %d в той же точке %s" % [
				new_meta.get("reason", ""),
				new_priority,
				old_priority,
				new_progress,
			]
		)
		return false
	return true


func save_checkpoint(
	timeline: String,
	label: String = "",
	dialogic_state: Dictionary = {},
	reason: String = ""
) -> bool:
	var def := get_checkpoint_definition(reason)
	if def.is_empty():
		push_warning("GameSaveManager: неизвестная причина '%s'" % reason)
		return false

	var resolved_timeline: String = timeline if not timeline.is_empty() else str(def.get("timeline", ""))
	var resolved_label: String = label if not label.is_empty() else str(def.get("label", ""))
	var checkpoint_id: String = str(def.get("checkpoint_id", reason))
	var visual_state_id: String = str(def.get("visual_state_id", ""))

	if resolved_timeline.is_empty() or not resolved_timeline in VALID_TIMELINES:
		push_warning("GameSaveManager: неизвестный timeline '%s'" % resolved_timeline)
		return false

	var new_meta := {
		"chapter_index": int(def.get("chapter_index", 0)),
		"scene_index": int(def.get("scene_index", 0)),
		"checkpoint_order": int(def.get("checkpoint_order", 0)),
		"priority": int(def.get("priority", 0)),
		"reason": reason,
		"checkpoint_id": checkpoint_id,
		"visual_state_id": visual_state_id,
		"timeline": resolved_timeline,
		"label": resolved_label,
	}

	var existing := load_autosave()
	if not should_overwrite_checkpoint(existing, new_meta):
		return false

	var payload := {
		"version": SAVE_VERSION,
		"saved_at_unix": Time.get_unix_time_from_system(),
		"checkpoint_id": checkpoint_id,
		"visual_state_id": visual_state_id,
		"location_id": str(def.get("location_id", "")),
		"background_id": str(def.get("background_id", "")),
		"timeline": resolved_timeline,
		"label": resolved_label,
		"reason": reason,
		"chapter_index": new_meta["chapter_index"],
		"scene_index": new_meta["scene_index"],
		"checkpoint_order": new_meta["checkpoint_order"],
		"priority": new_meta["priority"],
		"dialogic_state": dialogic_state.duplicate(true),
	}

	var json_text := JSON.stringify(payload, "\t")
	var file := FileAccess.open(AUTOSAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameSaveManager: не удалось записать autosave: %s" % AUTOSAVE_PATH)
		return false
	file.store_string(json_text)
	file.close()
	print(
		"[Autosave WRITE] checkpoint_id=%s visual_state_id=%s timeline=%s label=%s ch=%d order=%d" % [
			checkpoint_id,
			visual_state_id,
			resolved_timeline,
			resolved_label,
			new_meta["chapter_index"],
			new_meta["checkpoint_order"],
		]
	)
	return true


func load_autosave() -> Dictionary:
	if not FileAccess.file_exists(AUTOSAVE_PATH):
		return {}

	var file := FileAccess.open(AUTOSAVE_PATH, FileAccess.READ)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	var data: Dictionary = parsed
	var version := int(data.get("version", 0))
	if version == 1:
		data = _migrate_v1_to_v2(data)
		version = 2
	if version == 2:
		data = _migrate_v2_to_v3(data)
	elif version != SAVE_VERSION:
		return {}

	var timeline: String = str(data.get("timeline", ""))
	if timeline.is_empty() or not timeline in VALID_TIMELINES:
		return {}

	if not data.has("chapter_index"):
		_enrich_progress_fields(data)
	if not data.has("visual_state_id"):
		_enrich_visual_fields(data)

	return data


func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	_enrich_progress_fields(data)
	data["version"] = 2
	return data


func _migrate_v2_to_v3(data: Dictionary) -> Dictionary:
	_enrich_visual_fields(data)
	if not data.has("checkpoint_id"):
		data["checkpoint_id"] = GameCheckpointRegistry.resolve_checkpoint_id(str(data.get("reason", "")))
	data["version"] = SAVE_VERSION
	return data


func _enrich_progress_fields(data: Dictionary) -> void:
	var reason := str(data.get("reason", ""))
	var def := get_checkpoint_definition(reason)
	if not def.is_empty():
		data["chapter_index"] = int(def.get("chapter_index", 0))
		data["scene_index"] = int(def.get("scene_index", 0))
		data["checkpoint_order"] = int(def.get("checkpoint_order", 0))
		data["priority"] = int(def.get("priority", 0))
		return

	var timeline := str(data.get("timeline", ""))
	data["chapter_index"] = _chapter_from_timeline_name(timeline)
	data["scene_index"] = 1
	data["checkpoint_order"] = 0
	data["priority"] = get_reason_priority(reason)


func _enrich_visual_fields(data: Dictionary) -> void:
	var reason := str(data.get("reason", ""))
	var def := get_checkpoint_definition(reason)
	if def.is_empty():
		data["checkpoint_id"] = reason
		data["visual_state_id"] = GameCheckpointRegistry.FALLBACK_VISUAL_STATE
		data["location_id"] = ""
		data["background_id"] = ""
		return
	data["checkpoint_id"] = str(def.get("checkpoint_id", reason))
	if reason == "scene1_completed":
		data["checkpoint_id"] = "chapter2_entry"
	data["visual_state_id"] = str(def.get("visual_state_id", GameCheckpointRegistry.FALLBACK_VISUAL_STATE))
	data["location_id"] = str(def.get("location_id", ""))
	data["background_id"] = str(def.get("background_id", ""))


func _chapter_from_timeline_name(timeline: String) -> int:
	if timeline.begins_with("scene"):
		var digits := ""
		for i in range(5, timeline.length()):
			var ch: String = timeline[i]
			if ch.is_valid_int():
				digits += ch
			else:
				break
		if not digits.is_empty():
			return digits.to_int()
	return 1


func log_autosave_contents(context: String) -> void:
	if not FileAccess.file_exists(AUTOSAVE_PATH):
		print("[Autosave READ:%s] файл отсутствует (%s)" % [context, AUTOSAVE_PATH])
		return

	var data := load_autosave()
	if data.is_empty():
		print("[Autosave READ:%s] файл есть, но данные невалидны" % context)
		return

	print(
		"[Autosave READ:%s] checkpoint_id=%s visual_state_id=%s ch=%d order=%d timeline=%s label=%s" % [
			context,
			data.get("checkpoint_id", ""),
			data.get("visual_state_id", ""),
			data.get("chapter_index", 0),
			data.get("checkpoint_order", 0),
			data.get("timeline", ""),
			data.get("label", ""),
		]
	)
