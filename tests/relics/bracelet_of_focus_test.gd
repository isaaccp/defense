extends GutTest

# Level has 1 enemy.
const basic_test_level_scene = preload("res://tests/actions/basic_test_level.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")
const heal = preload("res://skill_tree/actions/heal.tres")
const self_target = preload("res://skill_tree/targets/self.tres")
const bracelet_of_focus = preload("res://effects/relics/bracelet_of_focus.tres")

var level: Level
var character: Node2D
var behavior_component: BehaviorComponent
var heal_cooldown: float
var bracelet_cooldown_multiplier: float

func make_heal_behavior() -> StoredBehavior:
	var behavior = StoredBehavior.new()
	behavior.stored_rules.append(
		TestUtils.rule_def(self_target, heal)
	)
	return behavior

func before_each():
	level = basic_test_level_scene.instantiate()
	var heal_test_character = test_character.duplicate(true)
	heal_test_character.add_relic(bracelet_of_focus.name)
	level.initialize([heal_test_character])
	add_child_autoqfree(level)
	# Set up character.
	character = level.characters.get_child(0)
	behavior_component = character.get_component_or_die(BehaviorComponent)
	var action = Action.make_runnable_action(heal)
	heal_cooldown = action.cooldown
	var bracelet = bracelet_of_focus.effect_script.new() as Effect
	bracelet_cooldown_multiplier = bracelet.cooldown_multiplier

func test_effect_actuator():
	var effect_actuator: EffectActuatorComponent = character.get_component_or_die(EffectActuatorComponent)
	# Needed to load the relics from GameplayCharacter.
	effect_actuator.run()
	# Test that cooldown is modified as expected.
	var effect_log: Array[String] = []
	var new_cooldown = effect_actuator.modified_cooldown(heal, heal_cooldown, effect_log)
	assert_almost_eq(new_cooldown, heal_cooldown * bracelet_cooldown_multiplier, 0.01)
	assert_eq(effect_log.size(), 1)

func test_in_level():
	TestUtils.set_character_behavior(character, make_heal_behavior())
	level.start()
	watch_signals(behavior_component)
	var heal_cooldown = Action.make_runnable_action(heal).cooldown
	await wait_for_signal(behavior_component.behavior_updated, 1, "Waiting for behavior to update")
	await wait_for_signal(behavior_component.action_finished, 2, "Waiting for heal to finish")
	var eligible_at = behavior_component.action_cooldowns[heal.name()]
	assert_almost_eq(eligible_at, behavior_component.elapsed_time + heal_cooldown * bracelet_cooldown_multiplier, 0.05)
