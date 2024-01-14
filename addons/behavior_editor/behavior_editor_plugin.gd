@tool
extends EditorPlugin

var ui: ProgrammingUI
var _in_obj: StoredBehavior

func _exit_tree():
	if is_instance_valid(ui):
		remove_control_from_bottom_panel(ui)
		ui.free()

func _handles(o: Object) -> bool:
	return o is StoredBehavior

func _edit(o: Object):
	_in_obj = o as StoredBehavior
	if not o:
		if is_instance_valid(ui):
			remove_control_from_bottom_panel(ui)
			ui.free()
		return
	ui = preload("res://ui/programming_ui.tscn").instantiate()
	ui.saved.connect(_on_save)
	ui.editor_initialize(o)
	add_control_to_bottom_panel(ui, "Behavior Editor")

func _on_save(b: StoredBehavior):
	# Just overwriting the input makes the change appear in the inspector.
	# Note: This changes the resource IDs of the rules,
	# which can be a bit ugly in diffs.
	_in_obj.stored_rules = b.stored_rules
	# But it makes sense to write it to disk too,
	# so you don't have to remember to save the enclosing scene.
	if _in_obj.resource_path:
		ResourceSaver.save(_in_obj)

func _on_cancel():
	remove_control_from_bottom_panel(ui)
	ui.free()
