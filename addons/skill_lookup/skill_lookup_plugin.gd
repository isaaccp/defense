extends EditorInspectorPlugin

const SkillNameEditor = preload("res://addons/skill_lookup/skill_name_editor.gd")

func _can_handle(object: Object):
	# Add more if needed, for now this is the only place that has editable
	# StringNames that need to be looked up.
	print(object)
	if object is SkillTreeState:
		return true
	return false

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags, wide):
	if type == TYPE_STRING_NAME:
		add_property_editor(name, SkillNameEditor.new())
		# TODO: Change to "return true" once https://github.com/godotengine/godot/issues/71236 is fixed.
		return false
	else:
		return false
