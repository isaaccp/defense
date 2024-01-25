@tool
extends ParamSkill

class_name TargetSelectionDef

## Type of Target that this selector returns.
@export var type: Target.Type
## Description for target.
@export_multiline var description_text: String = "<missing description>"
## Selector script.
@export var selector_script: GDScript
## Whether the target is sortable. If it is, it must provide
## the {sort} placeholder in params.editor_string.
@export var sortable = true

var default_sort = preload("res://skill_tree/target_sorts/closest_first.tres")
# TODO: Allow for target selections to have different default
# sorts if we have a check on the tree building to validate that
# the player must have unlocked that one first.

const NoTarget = &"__no_target__"

func _init():
	skill_type = SkillType.TARGET
	# Needs to be called deferred so values from resource are set.
	_set_default.call_deferred()

func _set_default():
	if sortable:
		params.set_placeholder_value(SkillParams.PlaceholderId.SORT, default_sort)

func sort() -> TargetSort:
	assert(restored_skill_params.sort)
	return restored_skill_params.sort

func validate():
	if sortable:
		if not params.editor_string.contains("{sort}"):
			print("%s is sortable but editor_string (%s) doesn't contain {sort}" % [name(), params.editor_string])

func name() -> String:
	return skill_name

func description():
	return "%s\nTarget Type: %s" % [description_text, Target.target_type_str(type)]
