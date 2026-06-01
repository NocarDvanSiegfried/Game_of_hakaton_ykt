extends Node

const MAIN_SCENE := "res://scenes/main.tscn"

var start_timeline_override := ""


func set_start_timeline_override(timeline_name: String) -> void:
	start_timeline_override = timeline_name


func consume_start_timeline_override() -> String:
	var timeline_name := start_timeline_override
	start_timeline_override = ""
	return timeline_name


func prepare_debug_vars_for_timeline(timeline_name: String) -> void:
	if timeline_name.is_empty():
		return

	# These values keep later timelines on a valid story path for visual testing.
	Dialogic.VAR.scene1_choice = "debug"
	Dialogic.VAR.scene2_path = "debug"
	Dialogic.VAR.scene3_path = "debug"
	Dialogic.VAR.boss_tactic = "debug"
	Dialogic.VAR.boss_end = "spare"
	Dialogic.VAR.bargyy_bond = max(Dialogic.VAR.bargyy_bond, 2)
	Dialogic.VAR.kunney_courage = max(Dialogic.VAR.kunney_courage, 2)
	Dialogic.VAR.shadow_runner_outcome = "tracked"
	Dialogic.VAR.shaman_trust = max(Dialogic.VAR.shaman_trust, 2)

	if timeline_name == "ending_bad_early":
		Dialogic.VAR.accepted_initiation = false
		return

	if _timeline_index(timeline_name) >= _timeline_index("scene4_timeline"):
		Dialogic.VAR.accepted_initiation = true
		Dialogic.VAR.met_emeehsin_full = true
		Dialogic.VAR.knows_lunar_maiden = true
		Dialogic.VAR.knows_judge = true

	if _timeline_index(timeline_name) >= _timeline_index("scene5_timeline"):
		Dialogic.VAR.scene4_memory = "debug"
		Dialogic.VAR.forgiveness_choice = "witness"
		Dialogic.VAR.empathy_score = max(Dialogic.VAR.empathy_score, 2)
		Dialogic.VAR.water_truth = max(Dialogic.VAR.water_truth, 2)
		Dialogic.VAR.ytyyr_outcome = "remembered"

	if _timeline_index(timeline_name) >= _timeline_index("scene6_timeline"):
		Dialogic.VAR.scene5_forge_path = "debug"
		Dialogic.VAR.forge_rhythm = max(Dialogic.VAR.forge_rhythm, 2)
		Dialogic.VAR.idea_strength = max(Dialogic.VAR.idea_strength, 2)
		Dialogic.VAR.knife_resonance = max(Dialogic.VAR.knife_resonance, 2)
		Dialogic.VAR.timir_outcome = "resonance"

	if _timeline_index(timeline_name) >= _timeline_index("scene7_timeline"):
		Dialogic.VAR.scene6_verdict = "true_justice"
		Dialogic.VAR.guilt_score = max(Dialogic.VAR.guilt_score, 1)
		Dialogic.VAR.mercy_score = max(Dialogic.VAR.mercy_score, 2)
		Dialogic.VAR.truth_seen = max(Dialogic.VAR.truth_seen, 2)
		Dialogic.VAR.khara_outcome = "balanced"

	if _timeline_index(timeline_name) >= _timeline_index("scene8_timeline"):
		Dialogic.VAR.scene7_cut_choice = "guilt"
		Dialogic.VAR.memory_weight = max(Dialogic.VAR.memory_weight, 2)
		Dialogic.VAR.self_acceptance = max(Dialogic.VAR.self_acceptance, 2)
		Dialogic.VAR.pain_released = max(Dialogic.VAR.pain_released, 2)
		Dialogic.VAR.butcher_outcome = "held_by_family"

	if _timeline_index(timeline_name) >= _timeline_index("scene9_timeline"):
		Dialogic.VAR.scene8_meaning_choice = "debug"
		Dialogic.VAR.chaos_acceptance = max(Dialogic.VAR.chaos_acceptance, 2)
		Dialogic.VAR.mirror_truth = max(Dialogic.VAR.mirror_truth, 2)
		Dialogic.VAR.false_life_released = max(Dialogic.VAR.false_life_released, 2)
		Dialogic.VAR.oibon_outcome = "harmonized"

	if _timeline_index(timeline_name) >= _timeline_index("scene10_timeline"):
		Dialogic.VAR.scene9_ancestor_choice = "release"
		Dialogic.VAR.ancestral_guilt = max(Dialogic.VAR.ancestral_guilt, 1)
		Dialogic.VAR.father_truth = max(Dialogic.VAR.father_truth, 3)
		Dialogic.VAR.forgiveness_strength = max(Dialogic.VAR.forgiveness_strength, 2)
		Dialogic.VAR.uguyar_outcome = "guide_unlocked"
		Dialogic.VAR.heart_resonance = max(Dialogic.VAR.heart_resonance, 2)
		Dialogic.VAR.spirits_support = max(Dialogic.VAR.spirits_support, 2)
		Dialogic.VAR.sacrifice_score = max(Dialogic.VAR.sacrifice_score, 1)


func _timeline_index(timeline_name: String) -> int:
	var order := [
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
		"ending_bad_early",
	]
	return order.find(timeline_name)
