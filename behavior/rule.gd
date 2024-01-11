extends Resource

class_name Rule

@export var target_selection: TargetSelectionDef
@export var action: ActionDef
@export var condition: ConditionDef

func string_with_target(target: Target) -> String:
	return "%s -> %s [%s] (%s)" % [
		action.name(),
		target_selection.name(),
		target,
		condition.name(),
	]
func _to_string() -> String:
	return "%s -> %s (%s)" % [
		action.name(),
		target_selection.name(),
		condition.name(),
	]
