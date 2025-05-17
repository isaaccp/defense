extends GutTest

const _ui_scene = preload("res://ui/programming_ui.tscn")

var _sender = InputSender.new(Input)

func after_each():
	_sender.release_all()
	_sender.clear()

func test_last_empty():
	var ui = _ui_scene.instantiate() as ProgrammingUI
	ui._initialize_from_test_character()
	add_child_autoqfree(ui)

	var behavior_editor = ui.get_node("%BehaviorEditor") as BehaviorEditor
	var behavior_editor_view = behavior_editor.get_node("%BehaviorEditorView") as BehaviorEditorView
	var last_rule = _last_rule_line(behavior_editor_view)
	assert_true(behavior_editor_view._is_empty(last_rule), "last rule should be an empty placeholder")

# Test disabled as now _can_drop_data gets invoked with real mouse coordinates
# instead of with inputsender coordinates.
# See https://github.com/bitwes/Gut/issues/646#issuecomment-2888592657
func _test_empty_after_new_drop():
	var ui = _ui_scene.instantiate() as ProgrammingUI
	ui._initialize_from_test_character()
	add_child_autoqfree(ui)
	ui.show()
	await wait_frames(1)

	var toolbox = ui.get_node("%Toolbox") as Tree
	var src = _find_toolbox_item(toolbox, "Once")
	assert_not_null(src, "Could not find Once")
	var src_rect = toolbox.get_item_area_rect(src, 0)

	var behavior_editor = ui.get_node("%BehaviorEditor") as BehaviorEditor
	var behavior_editor_view = behavior_editor.get_node("%BehaviorEditorView") as BehaviorEditorView
	var start_count = behavior_editor_view.get_root().get_child_count()
	var last_rule = _last_rule_line(behavior_editor_view)
	assert_true(behavior_editor_view._is_empty(last_rule), "last rule should be an empty placeholder")
	var dest_rect = behavior_editor_view.get_item_area_rect(last_rule, BehaviorEditorView.Column.CONDITION)

	await _drag_drop(toolbox.global_position + src_rect.get_center(),
		behavior_editor_view.global_position + dest_rect.get_center())

	assert_gt(behavior_editor_view.get_root().get_child_count(), start_count)

	var new_last_rule = _last_rule_line(behavior_editor_view)
	assert_true(behavior_editor_view._is_empty(new_last_rule), "new last rule should be an empty placeholder")
	assert_not_same(new_last_rule, last_rule)

	if is_failing(): # TODO: Only if !gut.add_children_to._cmdln_mode?
		pause_before_teardown()

# Test disabled as now _can_drop_data gets invoked with real mouse coordinates
# instead of with inputsender coordinates.
# See https://github.com/bitwes/Gut/issues/646#issuecomment-2888592657
func _test_noop_always_drop():
	# FIXME: Deal with orphans
	var ui = _ui_scene.instantiate() as ProgrammingUI
	ui._initialize_from_test_character()
	add_child_autoqfree(ui)
	ui.show()
	await wait_frames(1)

	var toolbox = ui.get_node("%Toolbox") as Tree
	var src = _find_toolbox_item(toolbox, "Always")
	assert_not_null(src, "Could not find Always")
	var src_rect = toolbox.get_item_area_rect(src, 0)

	var behavior_editor = ui.get_node("%BehaviorEditor") as BehaviorEditor
	var behavior_editor_view = behavior_editor.get_node("%BehaviorEditorView") as BehaviorEditorView
	var start_count = behavior_editor_view.get_root().get_child_count()
	var last_rule = _last_rule_line(behavior_editor_view)
	assert_true(behavior_editor_view._is_empty(last_rule), "last rule should be an empty placeholder")
	var dest_rect = behavior_editor_view.get_item_area_rect(last_rule, BehaviorEditorView.Column.CONDITION)

	await _drag_drop(toolbox.global_position + src_rect.get_center(),
		behavior_editor_view.global_position + dest_rect.get_center())

	assert_eq(behavior_editor_view.get_root().get_child_count(), start_count)

	var new_last_rule = _last_rule_line(behavior_editor_view)
	assert_true(behavior_editor_view._is_empty(new_last_rule), "last rule should still be an empty placeholder")
	assert_same(new_last_rule, last_rule)

	if is_failing(): # TODO: Only if !gut.add_children_to._cmdln_mode?
		pause_before_teardown()

func _drag_drop(start_pos: Vector2, end_pos: Vector2):
	# FIXME: Stupid hack to avoid the large overlay taking input :-/
	gut.add_children_to._gui.hide()

	_sender.mouse_motion(start_pos)
	_sender.mouse_left_button_down(start_pos)

	# Start the drag.
	_sender.mouse_relative_motion(Vector2(10, 10))
	await wait_for_signal(self.drag_start, 1)
	assert_signal_emitted(self, 'drag_start')

	_sender.mouse_motion(end_pos)
	_sender.mouse_left_button_up(end_pos)

	# Make sure the reaction has been processed.
	await wait_for_signal(self.drag_stop, 1)
	assert_signal_emitted(self, 'drag_stop')
	assert_true(get_viewport().gui_is_drag_successful(), "drop should be successful")
	gut.add_children_to._gui.show()

signal drag_start
signal drag_stop

func _notification(what):
	if what == NOTIFICATION_DRAG_BEGIN:
		get_logger().info("Notification: DRAG_BEGIN")
		drag_start.emit()
	elif what == NOTIFICATION_DRAG_END:
		get_logger().info("Notification: DRAG_END")
		drag_stop.emit()

func _last_rule_line(behavior_editor_view: BehaviorEditorView) -> TreeItem:
	assert_gt(behavior_editor_view.get_root().get_child_count(), 0, "some rule lines must be present in behavior list")
	return behavior_editor_view.get_root().get_children()[-1]

func _find_toolbox_item(toolbox: Tree, text: String) -> TreeItem:
	for header in toolbox.get_root().get_children():
		for c in header.get_children():
			if c.get_text(0) == text:
				return c
	return null
