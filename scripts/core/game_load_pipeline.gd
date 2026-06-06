extends Node
## Общий load pipeline (заготовка autoload).
## Continue и New Game по-прежнему идут через GameSession + main.gd + GameSaveManager.

const SOURCE_AUTOSAVE := "autosave"
const SOURCE_MANUAL := "manual"
const SOURCE_CONTINUE := "continue"


func normalize_save_data(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return {}
	return data.duplicate(true)


func select_autosave() -> Dictionary:
	return GameSaveManager.load_autosave()


func select_manual_slot(slot_id: String) -> Dictionary:
	return ManualSaveManager.load_slot(slot_id)
