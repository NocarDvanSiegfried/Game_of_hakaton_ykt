class_name SettingsOverlayHelper
extends RefCounted

const SETTINGS_MENU_SCENE := preload("res://scenes/ui/settings_menu.tscn")


static func open(
	parent: Node,
	pause_dialogic: bool = false,
	resume_dialogic_on_close: bool = true,
	hint_text: String = ""
) -> Control:
	var menu := SETTINGS_MENU_SCENE.instantiate() as Control
	menu.set_dialogic_pause(pause_dialogic)
	if menu.has_method("set_resume_dialogic_on_close"):
		menu.set_resume_dialogic_on_close(resume_dialogic_on_close)
	if not hint_text.is_empty() and menu.has_method("set_hint_text"):
		menu.set_hint_text(hint_text)
	parent.add_child(menu)
	return menu
