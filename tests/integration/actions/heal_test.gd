extends GutTest

# Level has 1 enemy.
const empty_level_scene = preload("res://tests/integration/actions/empty_level.tscn")
const heal_scene = preload("res://behavior/actions/scenes/heal.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")
const heal = preload("res://skill_tree/actions/heal.tres")
const self_target = preload("res://skill_tree/targets/self.tres")

var level: Level
var character: Node2D
var character_behavior: BehaviorComponent
var character_vitals: VitalsComponent
var heal_amount: int

func make_heal_behavior() -> StoredBehavior:
	var behavior = StoredBehavior.new()
	behavior.stored_rules.append(
		TestUtils.rule_def(self_target, heal)
	)
	return behavior

func before_all():
	var heal = heal_scene.instantiate()
	heal_amount = -Component.get_or_die(heal, HitboxComponent.component).hit_effect.damage
	heal.free()

func before_each():
	level = empty_level_scene.instantiate()
	level.initialize([test_character])
	add_child_autoqfree(level)
	# Set up character.
	character = level.characters.get_child(0)
	character_behavior = BehaviorComponent.get_or_die(character)
	character_vitals = character.get_component_or_die(VitalsComponent) as VitalsComponent

func test_heal_works():
	TestUtils.set_character_behavior(character, make_heal_behavior())

	await wait_frames(1)
	character_vitals.test_set_vital_current(VitalsComponent.VitalType.HEALTH, 5.0)

	level.start()
	watch_signals(character_behavior)
	watch_signals(character_vitals)
	await wait_seconds(0.6, "Waiting for heal")
	assert_signal_emitted(character_behavior, "behavior_updated")
	# First update is focus being re-plenished, second update is the heal.
	var vital_update = get_signal_parameters(character_vitals, "vital_updated", 1)[0] as VitalsComponent.VitalUpdate
	assert_eq(vital_update.current_value - vital_update.prev_value, heal_amount)
