@tool
extends EditorPlugin

var ui: ProgrammingUI
var _in_obj: BehaviorLibrary

func _exit_tree():
	if is_instance_valid(ui):
		remove_control_from_bottom_panel(ui)
		ui.free()

func _handles(o: Object) -> bool:
	return o is BehaviorLibrary

func _edit(o: Object):
	_in_obj = o as BehaviorLibrary
	if not o:
		if is_instance_valid(ui):
			remove_control_from_bottom_panel(ui)
			ui.free()
		return
	ui = preload("res://ui/programming_ui.tscn").instantiate()
	ui.saved.connect(_on_save)
	ui.library_editor_initialize(o)
	add_control_to_bottom_panel(ui, "Behavior Library")

func _on_save(b: BehaviorLibrary):
	# Just overwriting the input makes the change appear in the inspector.
	# Note: This changes the resource IDs of the rules,
	# which can be a bit ugly in diffs.
	_in_obj.behaviors = b.behaviors
	# But it makes sense to write it to disk too,
	# so you don't have to remember to save the enclosing scene.
	if _in_obj.resource_path:
		ResourceSaver.save(_in_obj)

func _on_cancel():
	remove_control_from_bottom_panel(ui)
	ui.free()
