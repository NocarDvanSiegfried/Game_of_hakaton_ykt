extends Node
## Stops Dialogic voice channels when dialogue advances or another speaker talks.
## Timeline voice uses separate channels (narrator_voice, ebe_voice); they do not
## replace each other, so we stop them explicitly on skip/advance.

const VOICE_CHANNELS: Array[String] = ["narrator_voice", "ebe_voice"]
const EBE_SPEAKER_ID := "ebe"
const NARRATOR_SPEAKER_ID := "narrator"

var _dialogic_connected := false


func _ready() -> void:
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

	_dialogic_connected = true


func _on_dialogic_action() -> void:
	_ensure_dialogic_connected()
	# First click while text reveals: keep voice. Next click advances: stop voice.
	if Dialogic.current_state == Dialogic.States.REVEALING_TEXT:
		return
	stop_voice_channels()


func _on_about_to_show_text(info: Dictionary) -> void:
	_ensure_dialogic_connected()
	var speaker_id := _speaker_id_from_info(info)
	match speaker_id:
		EBE_SPEAKER_ID:
			stop_channels(["narrator_voice"])
		NARRATOR_SPEAKER_ID:
			stop_channels(["ebe_voice"])
		_:
			stop_voice_channels()


func _on_timeline_ended() -> void:
	stop_voice_channels()


func stop_voice_channels() -> void:
	stop_channels(VOICE_CHANNELS)


func stop_channels(channels: Array) -> void:
	_ensure_dialogic_connected()
	if not Dialogic.has_subsystem("Audio"):
		return
	for channel_name in channels:
		Dialogic.Audio.update_audio(channel_name, "", {"fade_length": 0.0, "loop": false})


func _speaker_id_from_info(info: Dictionary) -> String:
	var character: Variant = info.get("character")
	if character == null:
		return NARRATOR_SPEAKER_ID
	if character is DialogicCharacter:
		return character.get_identifier()
	return str(character)
