class_name SettingsOverlayHelper
extends RefCounted

const SETTINGS_MENU_SCENE := preload("res://scenes/ui/settings_menu.tscn")


static func open(parent: Node, pause_dialogic: bool = false) -> Control:
	var menu := SETTINGS_MENU_SCENE.instantiate() as Control
	menu.set_dialogic_pause(pause_dialogic)
	parent.add_child(menu)
	return menu
