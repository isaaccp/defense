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
}

@export var id: Id
@export var type: Target.Type
@export var sortable = true
var default_sort = preload("res://skill_tree/target_sorts/closest_first.tres")
# TODO: Allow for target selections to have different default
# sorts if we have a check on the tree building to validate that
# the player must have unlocked that one first.

static func target_selection_name(target_selection_id: Id) -> String:
	return Id.keys()[target_selection_id].capitalize()

func validate():
	if sortable:
		if not params.editor_string.contains("{sort}"):
			print("%s is sortable but editor_string (%s) doesn't contain {sort}" % [name(), params.editor_string])

func name() -> String:
	return target_selection_name(id)
