@tool
extends EditorPlugin

var ui: ProgrammingUI
var _in_obj: StoredBehavior
var _visible = false

func _enter_tree():
	# Initialization the plugin.
	ui = preload("res://ui/programming_ui.tscn").instantiate()
	ui.saved.connect(_on_save)
	ui.canceled.connect(_on_cancel)

func _exit_tree():
	# Clean-up the plugin.
	_make_visible(false)
	ui.free()

func _handles(o: Object) -> bool:
	return o is StoredBehavior

func _edit(o: Object):
	_in_obj = o as StoredBehavior
	if not o:
		_make_visible(false)
		return
	ui.editor_initialize(o)
	_make_visible(true)

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
	# Reinitialize
	ui.editor_initialize(_in_obj)

func _make_visible(vis: bool):
	if vis and !_visible:
		add_control_to_bottom_panel(ui, "Behavior Editor")
		_visible = true
	elif not vis and _visible:
		remove_control_from_bottom_panel(ui)
		_visible = false
