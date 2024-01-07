extends GutTest

const body_scene = preload("res://character/character.tscn")

var body: CharacterBody2D
var behavior_component: BehaviorComponent

# TODO: Add some "do nothing" action and use it so it's faster
# than using heal here which has a cooldown.
# Using heal self as it can trigger without any other setup.
func make_behavior(condition_id: ConditionDef.Id) -> Behavior:
	var behavior = Behavior.new()
	behavior.rules.append(
		Rule.make(
			SkillManager.make_target_selection_instance(TargetSelectionDef.Id.SELF),
			SkillManager.make_action_instance(ActionDef.Id.HEAL),
			SkillManager.make_condition_instance(condition_id),
		)
	)
	return behavior

func before_each():
	body = body_scene.instantiate()
	behavior_component = Component.get_behavior_component_or_die(body)
	behavior_component.persistent_game_state_component = null
	add_child_autoqfree(body)

func test_basic_behavior():
	behavior_component.behavior = make_behavior(ConditionDef.Id.ALWAYS)
	watch_signals(behavior_component)
	await wait_seconds(0.1, "Waiting to ensure nothing happens before we do run()")
	assert_signal_not_emitted(behavior_component, "behavior_updated")
	behavior_component.run()
	await wait_for_signal(behavior_component.behavior_updated, 0.1)
	assert_signal_emitted(behavior_component, "behavior_updated")
	TestUtils.assert_last_action(self, behavior_component, ActionDef.Id.HEAL)

	# Next update should be "no action" due to cooldown.
	await wait_for_signal(behavior_component.behavior_updated, 2.0)
	TestUtils.assert_last_action(self, behavior_component, ActionDef.Id.UNSPECIFIED)
	# Next one should be HEAL again as we can trigger indefinitely.
	await wait_for_signal(behavior_component.behavior_updated, 10.0)
	TestUtils.assert_last_action(self, behavior_component, ActionDef.Id.HEAL)
	assert_eq(TestUtils.count_action_triggered(self, behavior_component, ActionDef.Id.HEAL), 2)

func test_persistent_condition_instance():
	behavior_component.behavior = make_behavior(ConditionDef.Id.ONCE)
	watch_signals(behavior_component)
	await wait_seconds(0.1, "Waiting to ensure nothing happens before we do run()")
	assert_signal_not_emitted(behavior_component, "behavior_updated")
	behavior_component.run()
	await wait_for_signal(behavior_component.behavior_updated, 0.1)
	assert_signal_emitted(behavior_component, "behavior_updated")
	TestUtils.assert_last_action(self, behavior_component, ActionDef.Id.HEAL)

	# Next update should be "no action" due to cooldown.
	await wait_for_signal(behavior_component.behavior_updated, 2.0)
	TestUtils.assert_last_action(self, behavior_component, ActionDef.Id.UNSPECIFIED)

	# There should be no new trigger as condition ONCE prevents it from
	# running again.
	await wait_for_signal(behavior_component.behavior_updated, 10.0)
	TestUtils.assert_last_action(self, behavior_component, ActionDef.Id.UNSPECIFIED)
	assert_eq(TestUtils.count_action_triggered(self, behavior_component, ActionDef.Id.HEAL), 1)
