extends Node
## Управление громкостью по audio bus (autoload).
##
## Категории: Master, Music, Voice, SFX, Ambient.
## Значения хранятся линейно 0.0–1.0 в user://settings.cfg.

const SETTINGS_PATH := "user://settings.cfg"

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_VOICE := "Voice"
const BUS_SFX := "SFX"
const BUS_AMBIENT := "Ambient"

const SETTING_MASTER := "volume_master"
const SETTING_MUSIC := "volume_music"
const SETTING_VOICE := "volume_voice"
const SETTING_SFX := "volume_sfx"
const SETTING_AMBIENT := "volume_ambient"

## Линейная громкость по умолчанию (0.0 = тишина, 1.0 = 100 %).
const DEFAULT_VOLUMES := {
	SETTING_MASTER: 1.0,
	SETTING_MUSIC: 0.8,
	SETTING_VOICE: 1.0,
	SETTING_SFX: 0.75,
	SETTING_AMBIENT: 0.8,
}

const SETTING_TO_BUS := {
	SETTING_MASTER: BUS_MASTER,
	SETTING_MUSIC: BUS_MUSIC,
	SETTING_VOICE: BUS_VOICE,
	SETTING_SFX: BUS_SFX,
	SETTING_AMBIENT: BUS_AMBIENT,
}

## Порядок и подписи для экрана настроек (День 3).
const UI_VOLUME_ROWS: Array[Dictionary] = [
	{"key": SETTING_MASTER, "label": "Общая громкость"},
	{"key": SETTING_MUSIC, "label": "Музыка"},
	{"key": SETTING_VOICE, "label": "Голоса"},
	{"key": SETTING_SFX, "label": "Эффекты"},
	{"key": SETTING_AMBIENT, "label": "Фон / атмосфера"},
]

## Dialogic-каналы scene1 → bus (см. project.godot → dialogic/audio/channel_defaults).
const DIALOGIC_VOICE_CHANNELS: Array[String] = [
	"narrator_voice",
	"ebe_voice",
	"aisen_voice",
	"kunney_voice",
	"tongus_voice",
]

const DIALOGIC_AMBIENT_CHANNELS: Array[String] = [
	"yakut_night",
	"fireplace",
	"house_morning",
	"stove_embers",
	"blizzard",
	"snow_run",
]

## Пустое имя канала в .dtl = One-Shot SFX → bus SFX.
const DIALOGIC_SFX_CHANNEL := ""

const MUTE_THRESHOLD_LINEAR := 0.001
const MUTE_DB := -80.0

var _volumes: Dictionary = {}


func _ready() -> void:
	load_settings()
	apply_all()


func load_settings() -> void:
	_volumes = DEFAULT_VOLUMES.duplicate()
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		return
	for setting_key in DEFAULT_VOLUMES.keys():
		if config.has_section_key("audio", setting_key):
			_volumes[setting_key] = clampf(
				float(config.get_value("audio", setting_key)),
				0.0,
				1.0,
			)


func save_settings() -> void:
	var config := ConfigFile.new()
	for setting_key in _volumes.keys():
		config.set_value("audio", setting_key, _volumes[setting_key])
	config.save(SETTINGS_PATH)


func apply_all() -> void:
	for setting_key in SETTING_TO_BUS.keys():
		_apply_bus(SETTING_TO_BUS[setting_key], _volumes.get(setting_key, 1.0))


func reset_to_defaults(persist: bool = true) -> void:
	_volumes = DEFAULT_VOLUMES.duplicate()
	apply_all()
	if persist:
		save_settings()


func get_volume(setting_key: String) -> float:
	return float(_volumes.get(setting_key, DEFAULT_VOLUMES.get(setting_key, 1.0)))


func set_volume(setting_key: String, linear: float, persist: bool = true) -> void:
	if not SETTING_TO_BUS.has(setting_key):
		push_warning("AudioSettings: unknown setting key '%s'" % setting_key)
		return
	var clamped := clampf(linear, 0.0, 1.0)
	_volumes[setting_key] = clamped
	_apply_bus(SETTING_TO_BUS[setting_key], clamped)
	if persist:
		save_settings()


func get_bus_index(bus_name: String) -> int:
	return AudioServer.get_bus_index(bus_name)


func linear_to_bus_db(linear: float) -> float:
	if linear <= MUTE_THRESHOLD_LINEAR:
		return MUTE_DB
	return linear_to_db(linear)


func _apply_bus(bus_name: String, linear: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		push_warning("AudioSettings: bus '%s' not found. Import default_bus_layout.tres?" % bus_name)
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_bus_db(linear))


func get_setting_keys() -> Array[String]:
	var keys: Array[String] = []
	for key in DEFAULT_VOLUMES.keys():
		keys.append(key)
	return keys
