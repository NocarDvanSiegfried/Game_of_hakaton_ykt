extends Node
## Ручные сохранения (отдельно от autosave в GameSaveManager).
## Autoload-заготовка: не трогает user://bargyy_autosave.json и не вызывается из main.gd.

const MANUAL_SAVES_DIR := "user://manual_saves/"
const MANUAL_SAVE_VERSION := 1
const SLOT_IDS: PackedStringArray = ["001", "002", "003"]


func ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(MANUAL_SAVES_DIR):
		DirAccess.make_dir_recursive_absolute(MANUAL_SAVES_DIR)


func get_slot_path(slot_id: String) -> String:
	return MANUAL_SAVES_DIR + "save_%s.json" % slot_id


func has_any_manual_save() -> bool:
	for slot_id in SLOT_IDS:
		if slot_has_save(slot_id):
			return true
	return false


func slot_has_save(slot_id: String) -> bool:
	return FileAccess.file_exists(get_slot_path(slot_id))


func read_file_raw(slot_id: String) -> Dictionary:
	var path := get_slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func load_slot(slot_id: String) -> Dictionary:
	var data := read_file_raw(slot_id)
	if data.is_empty():
		return {}
	if int(data.get("save_version", 0)) != MANUAL_SAVE_VERSION:
		return {}
	if str(data.get("save_type", "")) != "manual":
		return {}
	return data


func delete_slot(slot_id: String) -> bool:
	var path := get_slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(path) == OK
