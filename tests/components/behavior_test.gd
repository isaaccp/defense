extends GutTest

const test_enemy_scene = preload("res://enemies/test_enemy.tscn")
const heal = preload("res://skill_tree/actions/heal.tres")
const target_self = preload("res://skill_tree/targets/self.tres")
const always = preload("res://skill_tree/conditions/always.tres")

var enemy: Enemy
var behavior_component: BehaviorComponent

# TODO: Add some "do nothing" action and use it so it's faster
# than using heal here which has a cooldown.
# Using heal self as it can trigger without any other setup.
func make_behavior(condition: ConditionDef) -> StoredBehavior:
	var behavior = StoredBehavior.new()
	behavior.stored_rules.append(
		TestUtils.rule_def(target_self, heal, condition)
	)
	return behavior

func before_each():
	enemy = test_enemy_scene.instantiate()
	behavior_component = BehaviorComponent.get_or_die(enemy)
	add_child_autoqfree(enemy)

func test_basic_behavior():
	behavior_component.stored_behavior = make_behavior(always)
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
	behavior_component.stored_behavior = make_behavior(preload("res://skill_tree/conditions/once.tres"))
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
