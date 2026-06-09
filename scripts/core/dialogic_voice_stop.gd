extends Node
## Stops Dialogic voice channels when the speaker changes or the player skips ahead.
## Slow advance through split narrator lines keeps one voice clip playing.
## Rapid clicks (skip) stop all voice channels immediately.
## Scene 1: soft ambient ducking while any voice channel is active.

const VOICE_CHANNELS: Array[String] = [
	"narrator_voice", "ebe_voice", "aisen_voice", "kunney_voice", "tongus_voice",
]
const AMBIENT_DUCK_CHANNELS: Array[String] = [
	"yakut_night", "fireplace", "house_morning", "stove_embers", "blizzard", "snow_run",
]
const EBE_SPEAKER_ID := "ebe"
const NARRATOR_SPEAKER_ID := "narrator"
const AISEN_SPEAKER_ID := "aisen"
const KUNNEY_SPEAKER_ID := "kunney"
const TONGUS_SPEAKER_ID := "tongus"
const SCENE1_TIMELINE_SUFFIX := "scene1_timeline.dtl"
## Two advances faster than this are treated as skip (ms).
const RAPID_ADVANCE_MS := 450
const VOICE_STOP_FADE_SEC := 0.07
const AMBIENT_DUCK_OFFSET_DB := -5.0
const AMBIENT_DUCK_ATTACK_SEC := 0.22
const AMBIENT_DUCK_RELEASE_SEC := 0.7
const AMBIENT_UNDUCK_POLL_SEC := 0.15

const CHANNEL_TO_SPEAKER := {
	"narrator_voice": NARRATOR_SPEAKER_ID,
	"ebe_voice": EBE_SPEAKER_ID,
	"aisen_voice": AISEN_SPEAKER_ID,
	"kunney_voice": KUNNEY_SPEAKER_ID,
	"tongus_voice": TONGUS_SPEAKER_ID,
}

const INTRO_COLD_SFX := [
	{"path": "res://assets/audio/scene_01/frost_trees_crack_1.wav", "volume": -8.0},
	{"path": "res://assets/audio/scene_01/frost_trees_crack_2.wav", "volume": -10.0},
]

var _dialogic_connected := false
var _last_advance_msec: int = 0
var _ambient_duck_active := false
var _ambient_duck_tweens: Dictionary = {}
var _unduck_poll_timer: Timer


func _ready() -> void:
	_unduck_poll_timer = Timer.new()
	_unduck_poll_timer.one_shot = false
	_unduck_poll_timer.wait_time = AMBIENT_UNDUCK_POLL_SEC
	_unduck_poll_timer.timeout.connect(_poll_ambient_unduck)
	add_child(_unduck_poll_timer)
	call_deferred("_ensure_dialogic_connected")


func _ensure_dialogic_connected() -> void:
	if _dialogic_connected or not is_instance_valid(Dialogic):
		return
	if not Dialogic.has_subsystem("Text") or not Dialogic.has_subsystem("Inputs"):
		return

	var about_to_show := Callable(self, "_on_about_to_show_text")
	if not Dialogic.Text.about_to_show_text.is_connected(about_to_show):
		Dialogic.Text.about_to_show_text.connect(about_to_show)

	var dialogic_action := Callable(self, "_on_dialogic_action")
	if not Dialogic.Inputs.dialogic_action.is_connected(dialogic_action):
		Dialogic.Inputs.dialogic_action.connect(dialogic_action)

	if not Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.connect(_on_timeline_ended)

	if Dialogic.has_subsystem("Audio"):
		var audio_started := Callable(self, "_on_dialogic_audio_started")
		if not Dialogic.Audio.audio_started.is_connected(audio_started):
			Dialogic.Audio.audio_started.connect(audio_started)

	_dialogic_connected = true


func _on_dialogic_action() -> void:
	_ensure_dialogic_connected()
	if Dialogic.current_state == Dialogic.States.REVEALING_TEXT:
		return

	var now_msec := Time.get_ticks_msec()
	var rapid_advance := _last_advance_msec > 0 and (now_msec - _last_advance_msec) <= RAPID_ADVANCE_MS
	_last_advance_msec = now_msec

	var channels := _channels_to_stop_on_advance(rapid_advance)
	if channels.is_empty():
		return
	stop_channels(channels)


func _on_about_to_show_text(info: Dictionary) -> void:
	_ensure_dialogic_connected()
	_last_advance_msec = 0
	_play_intro_cold_sfx_for_segment(info)

	var speaker_id := _speaker_id_from_info(info)
	match speaker_id:
		EBE_SPEAKER_ID:
			stop_channels(["narrator_voice", "aisen_voice", "kunney_voice", "tongus_voice"])
		NARRATOR_SPEAKER_ID:
			stop_channels(["ebe_voice", "aisen_voice", "kunney_voice", "tongus_voice"])
		AISEN_SPEAKER_ID:
			stop_channels(["narrator_voice", "ebe_voice", "kunney_voice", "tongus_voice"])
		KUNNEY_SPEAKER_ID:
			stop_channels(["narrator_voice", "ebe_voice", "aisen_voice", "tongus_voice"])
		TONGUS_SPEAKER_ID:
			stop_channels(["narrator_voice", "ebe_voice", "aisen_voice", "kunney_voice"])
		_:
			stop_voice_channels()

	if not info.get("append", false):
		_apply_ambient_duck(true)


func _on_dialogic_audio_started(_info: Dictionary) -> void:
	if not _is_scene1_timeline():
		return
	if _any_voice_channel_playing():
		_apply_ambient_duck(true)


func _play_intro_cold_sfx_for_segment(info: Dictionary) -> void:
	if not info.get("append", false):
		return
	if not Dialogic.has_subsystem("Audio"):
		return

	var segment_index: int = Dialogic.current_state_info.get("text_sub_idx", 0)
	if segment_index <= 0 or segment_index > INTRO_COLD_SFX.size():
		return

	var sfx: Dictionary = INTRO_COLD_SFX[segment_index - 1]
	Dialogic.Audio.update_audio("", sfx.path, {"volume": sfx.volume, "loop": false})


func _on_timeline_ended() -> void:
	stop_voice_channels()
	_last_advance_msec = 0
	_apply_ambient_duck(false)


func stop_voice_channels() -> void:
	stop_channels(VOICE_CHANNELS)


func stop_channels(channels: Array) -> void:
	_ensure_dialogic_connected()
	if not Dialogic.has_subsystem("Audio"):
		return
	for channel_name in channels:
		Dialogic.Audio.update_audio(
			channel_name,
			"",
			{"fade_length": VOICE_STOP_FADE_SEC, "loop": false}
		)
	_schedule_ambient_unduck_poll()


func _channels_to_stop_on_advance(rapid_advance: bool) -> Array[String]:
	if rapid_advance:
		return VOICE_CHANNELS.duplicate()

	if _is_mid_multiline_text_event():
		return []

	var current_speaker := _speaker_id_from_current_text_event()
	var next_speaker := _next_text_speaker_id()
	var between := _events_until_next_text()
	var stop_list: Array[String] = []

	for channel_name in VOICE_CHANNELS:
		var channel_speaker: String = CHANNEL_TO_SPEAKER.get(channel_name, "")
		if _has_voice_clip_in_events(between, channel_name):
			stop_list.append(channel_name)
			continue
		if current_speaker == channel_speaker and next_speaker == channel_speaker:
			continue
		if current_speaker == channel_speaker:
			stop_list.append(channel_name)

	return stop_list


func _is_mid_multiline_text_event() -> bool:
	var section_index: int = Dialogic.current_state_info.get("text_sub_idx", -1)
	if section_index < 0:
		return false

	var events: Array = Dialogic.current_timeline_events
	var event_index: int = Dialogic.current_event_idx
	if event_index < 0 or event_index >= events.size():
		return false
	if not events[event_index] is DialogicTextEvent:
		return false

	var section_count := _count_text_sections(events[event_index] as DialogicTextEvent)
	return section_index < section_count - 1


func _count_text_sections(text_event: DialogicTextEvent) -> int:
	var split_regex := RegEx.new()
	split_regex.compile(r"((\[n\]|\[n\+\])?((?!(\[n\]|\[n\+\]))(.|\n))+)")
	var count := 0
	for _match in split_regex.search_all(text_event.text):
		count += 1
	return max(count, 1)


func _has_voice_clip_in_events(events: Array, channel_name: String) -> bool:
	for event in events:
		if event is DialogicAudioEvent:
			var audio_event := event as DialogicAudioEvent
			if audio_event.channel_name == channel_name and not audio_event.file_path.is_empty():
				return true
	return false


func _events_until_next_text() -> Array:
	var events: Array = Dialogic.current_timeline_events
	var index: int = Dialogic.current_event_idx
	if index < 0 or index >= events.size():
		return []
	if not events[index] is DialogicTextEvent:
		return []

	var between: Array = []
	for event_index in range(index + 1, events.size()):
		var event: DialogicEvent = events[event_index]
		if event is DialogicTextEvent:
			break
		between.append(event)
	return between


func _next_text_speaker_id() -> String:
	var events: Array = Dialogic.current_timeline_events
	var index: int = Dialogic.current_event_idx
	for event_index in range(index + 1, events.size()):
		var event: DialogicEvent = events[event_index]
		if event is DialogicTextEvent:
			return _speaker_id_from_text_event(event as DialogicTextEvent)
	return ""


func _speaker_id_from_current_text_event() -> String:
	var events: Array = Dialogic.current_timeline_events
	var index: int = Dialogic.current_event_idx
	if index < 0 or index >= events.size():
		return ""
	if events[index] is DialogicTextEvent:
		return _speaker_id_from_text_event(events[index] as DialogicTextEvent)
	return ""


func _speaker_id_from_text_event(text_event: DialogicTextEvent) -> String:
	if text_event.character == null:
		return NARRATOR_SPEAKER_ID
	return text_event.character.get_identifier()


func _speaker_id_from_info(info: Dictionary) -> String:
	var character: Variant = info.get("character")
	if character == null:
		return NARRATOR_SPEAKER_ID
	if character is DialogicCharacter:
		return character.get_identifier()
	return str(character)


func _is_scene1_timeline() -> bool:
	if Dialogic.current_timeline == null:
		return false
	return Dialogic.current_timeline.resource_path.ends_with(SCENE1_TIMELINE_SUFFIX)


func _any_voice_channel_playing() -> bool:
	if not Dialogic.has_subsystem("Audio"):
		return false
	for channel_name in VOICE_CHANNELS:
		if Dialogic.Audio.is_channel_playing(channel_name):
			return true
	return false


func _ambient_base_volume_db(channel_name: String) -> float:
	var entry: Dictionary = Dialogic.current_state_info.get("audio", {}).get(channel_name, {})
	var overrides: Dictionary = entry.get("settings_overrides", {})
	return float(overrides.get("volume", 0.0))


func _apply_ambient_duck(duck: bool) -> void:
	if not _is_scene1_timeline() or not Dialogic.has_subsystem("Audio"):
		return

	if duck:
		_ambient_duck_active = true
		_unduck_poll_timer.start()
		for channel_name in AMBIENT_DUCK_CHANNELS:
			if not Dialogic.Audio.is_channel_playing(channel_name):
				continue
			var player: AudioStreamPlayer = Dialogic.Audio.current_audio_channels.get(channel_name)
			if player == null or not is_instance_valid(player):
				continue
			var target_db := _ambient_base_volume_db(channel_name) + AMBIENT_DUCK_OFFSET_DB
			_tween_ambient_player_volume(channel_name, player, target_db, AMBIENT_DUCK_ATTACK_SEC)
		return

	_ambient_duck_active = false
	_unduck_poll_timer.stop()
	for channel_name in AMBIENT_DUCK_CHANNELS:
		if not Dialogic.Audio.is_channel_playing(channel_name):
			continue
		var player: AudioStreamPlayer = Dialogic.Audio.current_audio_channels.get(channel_name)
		if player == null or not is_instance_valid(player):
			continue
		_tween_ambient_player_volume(
			channel_name,
			player,
			_ambient_base_volume_db(channel_name),
			AMBIENT_DUCK_RELEASE_SEC
		)


func _tween_ambient_player_volume(
	channel_name: String,
	player: AudioStreamPlayer,
	target_db: float,
	duration_sec: float
) -> void:
	if _ambient_duck_tweens.has(channel_name):
		var existing: Variant = _ambient_duck_tweens[channel_name]
		if existing is Tween and is_instance_valid(existing):
			(existing as Tween).kill()
	var tween := create_tween()
	_ambient_duck_tweens[channel_name] = tween
	tween.tween_property(player, "volume_db", target_db, duration_sec).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_OUT
	)


func _schedule_ambient_unduck_poll() -> void:
	if not _is_scene1_timeline():
		return
	if not _unduck_poll_timer.is_stopped():
		return
	_unduck_poll_timer.start()


func _poll_ambient_unduck() -> void:
	if not _ambient_duck_active or not _is_scene1_timeline():
		_unduck_poll_timer.stop()
		return
	if _any_voice_channel_playing():
		return
	_apply_ambient_duck(false)
