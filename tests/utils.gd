extends RefCounted

class_name TestUtils

static func set_character_behavior(character: Node2D, behavior: Behavior):
	var persistent_state = Component.get_persistent_game_state_component_or_die(character)
	persistent_state.state.behavior = behavior

static func count_action_triggered(test: GutTest, behavior: BehaviorComponent, action_name: StringName):
	var count = 0
	for i in test.get_signal_emit_count(behavior, "behavior_updated"):
		var params = test.get_signal_parameters(behavior, "behavior_updated", i)
		var name = params[0]
		if name == action_name:
			count += 1
	return count

static func assert_last_action(test: GutTest, behavior: BehaviorComponent, expected: StringName):
	var count = test.get_signal_emit_count(behavior, "behavior_updated")
	test.assert_ne(count, 0, "No actions emitted")
	var params = test.get_signal_parameters(behavior, "behavior_updated")
	test.assert_not_null(params)
	if not params:
		print("Unexpected lack of emit")
		dump_all_emits(test, behavior, "behavior_updated")
		return
	var got = params[0]
	test.assert_eq(got, expected, "Last action was %s instead of %s" % [got, expected])

static func assert_last_action_not(test: GutTest, behavior: BehaviorComponent, expected: StringName):
	var count = test.get_signal_emit_count(behavior, "behavior_updated")
	test.assert_ne(count, 0, "No actions emitted")
	var params = test.get_signal_parameters(behavior, "behavior_updated")
	var got = params[0]
	test.assert_not_null(params)
	if not params:
		print("Unexpected lack of emit")
		dump_all_emits(test, behavior, "behavior_updated")
		return
	test.assert_ne(got, expected, "Last action was %s, but we expected it not to be" % expected)

static func dump_all_emits(test: GutTest, object: Object, signal_name: String):
	for i in test.get_signal_emit_count(object, signal_name):
		# TODO: Figure out how to gut.p.
		print(test.get_signal_parameters(object, signal_name, i))
