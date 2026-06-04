extends Node
## Единый реестр checkpoint: прогресс, timeline/label, visual_state_id.

const CHECKPOINTS := {
	"scene1_after_video_morning": {
		"checkpoint_id": "scene1_after_video_morning",
		"chapter_index": 1,
		"scene_index": 1,
		"checkpoint_order": 20,
		"priority": 50,
		"timeline": "scene1_timeline",
		"label": "scene1_part2_morning",
		"visual_state_id": "scene1_morning_wakeup",
		"location_id": "scene1_house_morning",
		"background_id": "bg_scene1_house_window_blizzard",
	},
	"after_chapter_video": {
		"checkpoint_id": "scene1_after_video_morning",
		"chapter_index": 1,
		"scene_index": 1,
		"checkpoint_order": 20,
		"priority": 50,
		"timeline": "scene1_timeline",
		"label": "scene1_part2_morning",
		"visual_state_id": "scene1_morning_wakeup",
		"location_id": "scene1_house_morning",
		"background_id": "bg_scene1_house_window_blizzard",
	},
	"scene1_part3_yard": {
		"checkpoint_id": "scene1_part3_yard",
		"chapter_index": 1,
		"scene_index": 1,
		"checkpoint_order": 30,
		"priority": 50,
		"timeline": "scene1_timeline",
		"label": "scene1_part3_yard",
		"visual_state_id": "scene1_yard_outdoor",
		"location_id": "scene1_yard",
		"background_id": "bg_scene1_dog_tracks_yard",
	},
	"scene1_after_yard_choice": {
		"checkpoint_id": "scene1_after_yard_choice",
		"chapter_index": 1,
		"scene_index": 1,
		"checkpoint_order": 35,
		"priority": 60,
		"timeline": "scene1_timeline",
		"label": "scene1_after_yard_choice",
		"visual_state_id": "scene1_yard_outdoor",
		"location_id": "scene1_yard_after_choice",
		"background_id": "bg_scene1_dog_tracks_yard",
	},
	"scene1_part4_chase": {
		"checkpoint_id": "scene1_part4_chase",
		"chapter_index": 1,
		"scene_index": 1,
		"checkpoint_order": 40,
		"priority": 50,
		"timeline": "scene1_timeline",
		"label": "scene1_part4_chase",
		"visual_state_id": "scene1_forest_path",
		"location_id": "scene1_blizzard_chase",
		"background_id": "snowy_forest_path",
	},
	"scene1_part5_ice_hole": {
		"checkpoint_id": "scene1_part5_ice_hole",
		"chapter_index": 1,
		"scene_index": 1,
		"checkpoint_order": 50,
		"priority": 50,
		"timeline": "scene1_timeline",
		"label": "scene1_part5_ice_hole",
		"visual_state_id": "scene1_ice_hole",
		"location_id": "scene1_frozen_river",
		"background_id": "ice_tunnel",
	},
	"scene1_part6_tactics": {
		"checkpoint_id": "scene1_part6_tactics",
		"chapter_index": 1,
		"scene_index": 1,
		"checkpoint_order": 60,
		"priority": 50,
		"timeline": "scene1_timeline",
		"label": "scene1_part6_tactics",
		"visual_state_id": "scene1_ice_hole",
		"location_id": "scene1_frozen_river",
		"background_id": "ice_tunnel",
	},
	"scene1_part7_mercy": {
		"checkpoint_id": "scene1_part7_mercy",
		"chapter_index": 1,
		"scene_index": 1,
		"checkpoint_order": 70,
		"priority": 50,
		"timeline": "scene1_timeline",
		"label": "scene1_part7_mercy",
		"visual_state_id": "scene1_ice_hole",
		"location_id": "scene1_frozen_river",
		"background_id": "ice_tunnel",
	},
	"scene1_part8_after_battle": {
		"checkpoint_id": "scene1_part8_after_battle",
		"chapter_index": 1,
		"scene_index": 1,
		"checkpoint_order": 80,
		"priority": 50,
		"timeline": "scene1_timeline",
		"label": "scene1_part8_after_battle",
		"visual_state_id": "scene1_ice_hole",
		"location_id": "scene1_frozen_river_aftermath",
		"background_id": "ice_tunnel",
	},
	## Глава 1 завершена → Continue в начало scene2 (интро главы 2). Только в конце scene1_timeline.
	"chapter2_entry": {
		"checkpoint_id": "chapter2_entry",
		"chapter_index": 2,
		"scene_index": 1,
		"checkpoint_order": 0,
		"priority": 200,
		"timeline": "scene2_timeline",
		"label": "",
		"visual_state_id": "chapter2_start",
		"location_id": "chapter2_intro",
		"background_id": "chapter2_default",
	},
	## Старый reason в autosave v3 — то же, что chapter2_entry.
	"scene1_completed": {
		"checkpoint_id": "chapter2_entry",
		"chapter_index": 2,
		"scene_index": 1,
		"checkpoint_order": 0,
		"priority": 200,
		"timeline": "scene2_timeline",
		"label": "",
		"visual_state_id": "chapter2_start",
		"location_id": "chapter2_intro",
		"background_id": "chapter2_default",
	},
	## После интро главы 2 (не при автозапуске scene2 с нулевой строки).
	"scene2_intro_safe": {
		"checkpoint_id": "scene2_intro_safe",
		"chapter_index": 2,
		"scene_index": 1,
		"checkpoint_order": 5,
		"priority": 50,
		"timeline": "scene2_timeline",
		"label": "scene2_chapter2_intro",
		"visual_state_id": "chapter2_start",
		"location_id": "chapter2_intro",
		"background_id": "chapter2_default",
	},
	"scene2_safe_start": {
		"checkpoint_id": "scene2_intro_safe",
		"chapter_index": 2,
		"scene_index": 1,
		"checkpoint_order": 5,
		"priority": 50,
		"timeline": "scene2_timeline",
		"label": "scene2_chapter2_intro",
		"visual_state_id": "chapter2_start",
		"location_id": "chapter2_intro",
		"background_id": "chapter2_default",
	},
	"scene2_part1_tunnel": {
		"checkpoint_id": "scene2_part1_tunnel",
		"chapter_index": 2,
		"scene_index": 1,
		"checkpoint_order": 20,
		"priority": 50,
		"timeline": "scene2_timeline",
		"label": "scene2_part1_tunnel",
		"visual_state_id": "chapter2_ice_tunnel",
		"location_id": "chapter2_ice_tunnel",
		"background_id": "ice_tunnel",
	},
	"scene2_part2_labyrinth": {
		"checkpoint_id": "scene2_part2_labyrinth",
		"chapter_index": 2,
		"scene_index": 1,
		"checkpoint_order": 30,
		"priority": 50,
		"timeline": "scene2_timeline",
		"label": "scene2_part2_labyrinth",
		"visual_state_id": "chapter2_shadow_labyrinth",
		"location_id": "chapter2_labyrinth",
		"background_id": "chapter2_default",
	},
	"scene2_part3_kunney_pocket": {
		"checkpoint_id": "scene2_part3_kunney_pocket",
		"chapter_index": 2,
		"scene_index": 1,
		"checkpoint_order": 40,
		"priority": 50,
		"timeline": "scene2_timeline",
		"label": "scene2_part3_kunney_pocket",
		"visual_state_id": "chapter2_shadow_labyrinth",
		"location_id": "chapter2_kunney_cell",
		"background_id": "chapter2_default",
	},
	"scene2_part4_mirror_hall": {
		"checkpoint_id": "scene2_part4_mirror_hall",
		"chapter_index": 2,
		"scene_index": 1,
		"checkpoint_order": 50,
		"priority": 50,
		"timeline": "scene2_timeline",
		"label": "scene2_part4_mirror_hall",
		"visual_state_id": "chapter2_shadow_labyrinth",
		"location_id": "chapter2_mirror_hall",
		"background_id": "chapter2_default",
	},
	"scene2_part5_boss": {
		"checkpoint_id": "scene2_part5_boss",
		"chapter_index": 2,
		"scene_index": 1,
		"checkpoint_order": 60,
		"priority": 50,
		"timeline": "scene2_timeline",
		"label": "scene2_part5_boss",
		"visual_state_id": "chapter2_boss_arena",
		"location_id": "chapter2_boss",
		"background_id": "chapter2_default",
	},
	"scene2_part6_finale": {
		"checkpoint_id": "scene2_part6_finale",
		"chapter_index": 2,
		"scene_index": 1,
		"checkpoint_order": 70,
		"priority": 50,
		"timeline": "scene2_timeline",
		"label": "scene2_part6_finale",
		"visual_state_id": "chapter2_boss_arena",
		"location_id": "chapter2_finale",
		"background_id": "chapter2_default",
	},
}

const SIGNAL_REASON_ALIASES := {
	"checkpoint_scene2_start": "scene2_intro_safe",
	"checkpoint_scene2_intro_safe": "scene2_intro_safe",
	"checkpoint_chapter2_entry": "chapter2_entry",
}

const FALLBACK_VISUAL_STATE := "dialogic_neutral_dark"


func resolve_checkpoint_id(reason_or_id: String) -> String:
	if reason_or_id.is_empty():
		return ""
	if reason_or_id in CHECKPOINTS:
		return str(CHECKPOINTS[reason_or_id].get("checkpoint_id", reason_or_id))
	for key in CHECKPOINTS:
		if str(CHECKPOINTS[key].get("checkpoint_id", "")) == reason_or_id:
			return reason_or_id
	return reason_or_id


func get_definition(reason_or_checkpoint_id: String) -> Dictionary:
	if reason_or_checkpoint_id in CHECKPOINTS:
		return CHECKPOINTS[reason_or_checkpoint_id].duplicate(true)
	for _key in CHECKPOINTS:
		var def: Dictionary = CHECKPOINTS[_key]
		if str(def.get("checkpoint_id", "")) == reason_or_checkpoint_id:
			return def.duplicate(true)
	return {}


func signal_to_reason(signal_name: String) -> String:
	if signal_name in SIGNAL_REASON_ALIASES:
		return SIGNAL_REASON_ALIASES[signal_name]
	if signal_name.begins_with("checkpoint_"):
		return signal_name.substr("checkpoint_".length())
	return ""


func get_visual_state_id(reason_or_checkpoint_id: String) -> String:
	var def := get_definition(reason_or_checkpoint_id)
	if def.is_empty():
		return FALLBACK_VISUAL_STATE
	return str(def.get("visual_state_id", FALLBACK_VISUAL_STATE))
