extends GutTest

const _ui_scene = preload("res://ui/programming_ui.tscn")

# Earlier InputSender-based drag/drop tests were removed: _can_drop_data fires
# with real mouse coordinates rather than InputSender coordinates, so the drops
# never succeeded (gut issue 646). Tests below exercise the editor's data model
# and widget transitions directly, which doesn't require simulated input.

func test_last_empty_placeholder_present():
	var ui = _ui_scene.instantiate() as ProgrammingUI
	# Add to tree first so _ready cascades fire before initialize touches
	# the widgets; otherwise RuleWidget._target_cell is nil during setup.
	add_child_autoqfree(ui)
	ui._initialize_from_test_character()

	var view = _view_from_ui(ui)
	var rules = view._list.get_children()
	assert_gt(rules.size(), 0, "some rule widgets must be present")
	assert_true(rules[-1].is_empty(), "last rule should be an empty placeholder")

func test_conditions_cap_with_full_skills():
	var view = _make_view(true)
	assert_eq(view.conditions_cap, 3, "full skill access = cap of 3 conditions per rule")

func test_conditions_cap_with_no_meta_skills():
	var view = _make_view(false)
	assert_eq(view.conditions_cap, 1, "no meta skills = cap of 1 condition per rule")

func test_rule_summary_empty():
	var view = _make_view(true)
	var rule = view._list.get_children()[0]
	assert_eq(rule.rule_summary(), "", "empty placeholder has no summary")

func test_rule_summary_complete_no_conditions():
	var view = _make_view(true)
	var rule = view._list.get_children()[0]
	_fill_rule(rule, &"Enemy", &"Move To")
	var summary = rule.rule_summary()
	assert_string_contains(summary, "Action: ")
	assert_string_contains(summary, "Target: ")
	assert_string_contains(summary, "When: always")

func test_rule_summary_with_condition():
	var view = _make_view(true)
	var rule = view._list.get_children()[0]
	_fill_rule(rule, &"Enemy", &"Move To")
	rule._add_condition_row(SkillManager.make_condition_instance(&"Once"))
	var summary = rule.rule_summary()
	assert_string_contains(summary, "When: ")
	assert_true(not summary.contains("always"), "summary should drop 'always' once a condition is present")

func test_filling_placeholder_appends_new_placeholder():
	var view = _make_view(true)
	assert_eq(view._list.get_child_count(), 1, "starts with single placeholder")
	_fill_rule(view._list.get_children()[0], &"Enemy", &"Move To")
	assert_eq(view._list.get_child_count(), 2, "new placeholder appended after first rule is filled")
	assert_false(view._list.get_children()[0].is_empty())
	assert_true(view._list.get_children()[1].is_empty())

func test_get_behavior_excludes_placeholder():
	var view = _make_view(true)
	_fill_rule(view._list.get_children()[0], &"Enemy", &"Move To")
	var behavior = view.get_behavior()
	assert_not_null(behavior)
	assert_eq(behavior.stored_rules.size(), 1, "trailing placeholder excluded from saved behavior")
	var stored = behavior.stored_rules[0]
	assert_eq(stored.target_selection.name, &"Enemy")
	assert_eq(stored.action.name, &"Move To")

# --- Helpers ---

func _view_from_ui(ui: ProgrammingUI) -> BehaviorEditorView:
	var editor = ui.get_node("%BehaviorEditor") as BehaviorEditor
	return editor.get_node("%BehaviorEditorView") as BehaviorEditorView

func _make_view(full: bool) -> BehaviorEditorView:
	var view = BehaviorEditorView.new()
	add_child_autoqfree(view)
	var skills = SkillTreeState.new()
	skills.full = full
	view.initialize(skills)
	view.load_behavior(null)
	return view

func _fill_rule(rule, target_name: StringName, action_name: StringName) -> void:
	rule._target_cell.set_skill(SkillManager.make_target_selection_instance(target_name))
	rule._action_cell.set_skill(SkillManager.make_action_instance(action_name))
	rule.on_cell_changed()

func test_drag_to_reorder_rules():
	var view = _make_view(true)
	# 1. Fill first rule
	var rule_a = view._list.get_children()[0]
	_fill_rule(rule_a, &"Enemy", &"Move To")
	
	# 2. Fill second rule
	var rule_b = view._list.get_children()[1]
	_fill_rule(rule_b, &"Enemy", &"Sword Attack")
	
	var rules = view._list.get_children()
	assert_eq(rules.size(), 3, "should have Rule A, Rule B, and trailing placeholder")
	assert_eq(str(rules[0]._action_cell.get_skill()), "Move To")
	assert_eq(str(rules[1]._action_cell.get_skill()), "Sword Attack")
	assert_true(rules[2].is_empty(), "last child is placeholder")
	
	# 3. Simulate dragging Rule B (index 1)
	var drag_data = rules[1]._drag_button._get_drag_data(Vector2.ZERO)
	assert_true(drag_data.get("is_reorder_rule"))
	assert_eq(drag_data.rule_widget, rules[1])
	
	# 4. Simulate dropping Rule B on top half of Rule A (index 0, relative_y = 0)
	rules[0]._drop_data(Vector2(0, 0), drag_data)
	
	var reordered_rules = view._list.get_children()
	assert_eq(str(reordered_rules[0]._action_cell.get_skill()), "Sword Attack")
	assert_eq(str(reordered_rules[1]._action_cell.get_skill()), "Move To")
	assert_true(reordered_rules[2].is_empty())
	
	# 5. Drag Rule B (now index 0) and drop on bottom half of Rule A (now index 1, relative_y = 100)
	# Target rule size.y is typically around 30, so Y=100 is definitely the bottom half.
	reordered_rules[1].size.y = 30
	var new_drag_data = reordered_rules[0]._drag_button._get_drag_data(Vector2.ZERO)
	reordered_rules[1]._drop_data(Vector2(0, 100), new_drag_data)
	
	var reordered_rules_2 = view._list.get_children()
	assert_eq(str(reordered_rules_2[0]._action_cell.get_skill()), "Move To")
	assert_eq(str(reordered_rules_2[1]._action_cell.get_skill()), "Sword Attack")
	assert_true(reordered_rules_2[2].is_empty())

