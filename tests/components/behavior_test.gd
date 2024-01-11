extends GutTest

const body_scene = preload("res://character/character.tscn")
const heal = preload("res://skill_tree/actions/heal.tres")
const target_self = preload("res://skill_tree/targets/self.tres")
const always = preload("res://skill_tree/conditions/always.tres")

var body: CharacterBody2D
var behavior_component: BehaviorComponent

# TODO: Add some "do nothing" action and use it so it's faster
# than using heal here which has a cooldown.
# Using heal self as it can trigger without any other setup.
func make_behavior(condition: ConditionDef) -> Behavior:
	var behavior = Behavior.new()
	behavior.saved_rules.append(
		RuleDef.make(
			RuleSkillDef.from_skill(target_self),
			RuleSkillDef.from_skill(heal),
			RuleSkillDef.from_skill(condition),
		)
	)
	return behavior

func before_each():
	body = body_scene.instantiate()
	behavior_component = Component.get_behavior_component_or_die(body)
	behavior_component.persistent_game_state_component = null
	add_child_autoqfree(body)

func test_basic_behavior():
	behavior_component.behavior = make_behavior(always)
	watch_signals(behavior_component)
	await wait_seconds(0.1, "Waiting to ensure nothing happens before we do run()")
	assert_signal_not_emitted(behavior_component, "behavior_updated")
	behavior_component.run()
	await wait_for_signal(behavior_component.behavior_updated, 0.1)
	assert_signal_emitted(behavior_component, "behavior_updated")
	TestUtils.assert_last_action(self, behavior_component, heal.skill_name)

	# Next update should be "no action" due to cooldown.
	await wait_for_signal(behavior_component.behavior_updated, 2.0)
	TestUtils.assert_last_action(self, behavior_component, ActionDef.NoAction)
	# Next one should be HEAL again as we can trigger indefinitely.
	await wait_for_signal(behavior_component.behavior_updated, 10.0)
	TestUtils.assert_last_action(self, behavior_component, heal.skill_name)
	assert_eq(TestUtils.count_action_triggered(self, behavior_component, heal.skill_name), 2)

func test_persistent_condition_instance():
	behavior_component.behavior = make_behavior(preload("res://skill_tree/conditions/once.tres"))
	watch_signals(behavior_component)
	await wait_seconds(0.1, "Waiting to ensure nothing happens before we do run()")
	assert_signal_not_emitted(behavior_component, "behavior_updated")
	behavior_component.run()
	await wait_for_signal(behavior_component.behavior_updated, 0.1)
	assert_signal_emitted(behavior_component, "behavior_updated")
	TestUtils.assert_last_action(self, behavior_component, heal.skill_name)

	# Next update should be "no action" due to cooldown.
	await wait_for_signal(behavior_component.behavior_updated, 2.0)
	TestUtils.assert_last_action(self, behavior_component, ActionDef.NoAction)

	# There should be no new trigger as condition ONCE prevents it from
	# running again.
	await wait_for_signal(behavior_component.behavior_updated, 10.0)
	TestUtils.assert_last_action(self, behavior_component, ActionDef.NoAction)
	assert_eq(TestUtils.count_action_triggered(self, behavior_component, heal.skill_name), 1)
