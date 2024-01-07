@tool
extends ParamSkill

class_name TargetSelectionDef

enum Id {
	UNSPECIFIED,
	ENEMY,
	TOWER,
	SELF,
	SELF_OR_ALLY,
	ALLY,
	CENTER,
}

@export var id: Id
## Type of Target that this selector returns.
@export var type: Target.Type
## Description for target.
@export_multiline var description: String
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

static func target_selection_name(target_selection_id: Id) -> String:
	return Id.keys()[target_selection_id].capitalize()

func validate():
	if sortable:
		if not params.editor_string.contains("{sort}"):
			print("%s is sortable but editor_string (%s) doesn't contain {sort}" % [name(), params.editor_string])

func name() -> String:
	return target_selection_name(id)

func full_description():
	return "%s\n%s\nTarget Type: %s" % [name(), description, Target.target_type_str(type)]
