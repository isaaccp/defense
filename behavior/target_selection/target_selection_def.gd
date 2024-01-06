@tool
extends ParamSkill

class_name TargetSelectionDef

enum Id {
	UNSPECIFIED,
	CLOSEST_ENEMY,
	TOWER,
	SELF,
	SELF_OR_ALLY,
	ALLY,
	FARTHEST_ENEMY,
}

@export var id: Id
@export var type: Target.Type
@export var sortable = true

static func target_selection_name(target_selection_id: Id) -> String:
	return Id.keys()[target_selection_id].capitalize()

func validate():
	if sortable:
		if not params.editor_string.contains("{sort}"):
			print("%s is sortable but editor_string (%s) doesn't contain {sort}" % [name(), params.editor_string])

func name() -> String:
	return target_selection_name(id)

func _to_string() -> String:
	return target_selection_name(id)
