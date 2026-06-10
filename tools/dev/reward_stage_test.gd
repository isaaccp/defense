@tool
extends Node

## Quick-test scene for the reward stage screen.
##
## Open `reward_stage_test.tscn`, set the exports below to whatever you
## want to see, then press F6. The script synthesizes a minimal
## RunSaveState + party + roll'd reward sets and shows the
## RewardChoiceScreen exactly as it would appear after a fight.
##
## To test specific scenarios:
## - **Rest outcome**: set `damage_each_character > 0` so you can see HP
##   tick up after applying.
## - **Trainer flow**: bump `initial_xp_per_character` and make sure
##   `unlocked_skills` (or its default below) covers skills you want to
##   try acquiring.
## - **Relic flow**: set `relic_library` so the relic offer can roll a
##   specific relic.

@export_group("Party")
## Characters to include in the synthesized party. They get duplicated so
## the source .tres files are not mutated.
@export var characters: Array[GameplayCharacter] = []
@export var initial_xp_per_character: int = 500
## Subtract this much HP from each character before showing the screen,
## so the rest reward has something visible to heal.
@export var damage_each_character: int = 20

@export_group("Reward sets")
## Reward templates for the first set offered. Each template is `roll()`'d.
@export var set_a: Array[RewardDef] = []
## Reward templates for the second set offered.
@export var set_b: Array[RewardDef] = []

@export_group("Run config")
## Required if any reward in either set is a RelicRewardDef.
@export var relic_library: RelicLibrary
## Skills the trainer reward should consider unlockable. Default: all
## skills (so you can try acquiring anything). Set to a specific
## SkillTreeState resource to constrain the trainer's offerings.
@export var unlocked_skills_override: SkillTreeState

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if characters.is_empty():
		push_error("reward_stage_test: at least one character is required")
		return
	if set_a.is_empty() and set_b.is_empty():
		push_error("reward_stage_test: configure set_a and/or set_b")
		return
	var rss := _build_run_save_state()
	var stage_rewards := _build_stage_rewards(rss)
	var save_state := _build_save_state()
	var screen_scene := preload("res://ui/reward_choice_screen.tscn")
	var screen = screen_scene.instantiate()
	add_child(screen)
	screen._on_show({
		"save_state": save_state,
		"run_save_state": rss,
		"stage_rewards": stage_rewards,
	})
	screen.continue_pressed.connect(_on_continue)

func _build_run_save_state() -> RunSaveState:
	var gcs: Array[GameplayCharacter] = []
	for src in characters:
		var gc := src.duplicate(true) as GameplayCharacter
		gc.initialize(gc.name, 0)
		gc.health = max(1, gc.attributes.health - damage_each_character)
		gc.xp = initial_xp_per_character
		gcs.append(gc)
	var lp := LevelProvider.new()
	lp.relic_library = relic_library
	var rss := RunSaveState.new()
	rss.gameplay_characters = gcs
	rss.level_provider = lp
	rss.relic_library_state = RelicLibraryState.from_relic_library(relic_library)
	rss.seed = randi()
	rss.current_stage = 1
	rss.current_phase = RunSaveState.Phase.REWARD
	return rss

func _build_stage_rewards(rss: RunSaveState) -> StageRewards:
	var rng := RandomNumberGenerator.new()
	rng.seed = rss.seed
	var stage_rewards := StageRewards.new()
	stage_rewards.sets.append(_roll_set(set_a, rng, rss))
	stage_rewards.sets.append(_roll_set(set_b, rng, rss))
	return stage_rewards

func _roll_set(templates: Array[RewardDef], rng: RandomNumberGenerator, rss: RunSaveState) -> RewardSet:
	var rolled: Array[RewardDef] = []
	for tmpl in templates:
		rolled.append(tmpl.roll(rng, rss))
	var s := RewardSet.new()
	s.rewards = rolled
	return s

func _build_save_state() -> SaveState:
	var ss := SaveState.make_new()
	if unlocked_skills_override:
		ss.unlocked_skills = unlocked_skills_override
	else:
		# Default: everything unlocked so the trainer has lots to show.
		ss.unlocked_skills = SkillTreeState.new()
		ss.unlocked_skills.full = true
	return ss

func _on_continue() -> void:
	print("[reward_stage_test] Continue pressed — exiting")
	get_tree().quit()
