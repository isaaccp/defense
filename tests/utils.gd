extends RefCounted

class_name TestUtils

const always = preload("res://skill_tree/conditions/always.tres")
const barrel_scene = preload("res://enemies/barrel/barrel.tscn")

static func rule_def(target: TargetSelectionDef, action: ActionDef, condition: ConditionDef = always) -> RuleDef:
	return RuleDef.make(
		StoredParamSkill.from_skill(target),
		StoredParamSkill.from_skill(action),
		StoredParamSkill.from_skill(condition),
	)

static func set_character_behavior(character: Node2D, behavior: StoredBehavior):
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
	if got != expected:
		dump_all_emits(test, behavior, "behavior_updated")

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
	if got == expected:
		dump_all_emits(test, behavior, "behavior_updated")

static func dump_all_emits(test: GutTest, object: Object, signal_name: String):
	test.gut.p("Emits for %s" % signal_name)
	for i in test.get_signal_emit_count(object, signal_name):
		test.gut.p(test.get_signal_parameters(object, signal_name, i))

static func make_barrel(hp: int = 0):
	var barrel = barrel_scene.instantiate()
	if hp != 0:
		var attributes = barrel.get_component_or_die(AttributesComponent)
		attributes.base_attributes.health = hp
	return barrel
