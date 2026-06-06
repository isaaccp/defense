@tool
extends Resource

class_name Rule

@export var target_selection: TargetSelectionDef
@export var action: ActionDef
## @deprecated: kept for backward compatibility. Use `conditions` (array).
@export var condition: ConditionDef
## Conditions are ANDed together — a rule fires only if all of them pass.
@export var conditions: Array[ConditionDef]

func effective_conditions() -> Array[ConditionDef]:
	if not conditions.is_empty():
		return conditions
	if condition:
		var single: Array[ConditionDef] = [condition]
		return single
	return []

func string_with_target(target: Target) -> String:
	return "%s -> %s [%s] (%s)" % [
		action.name(),
		target_selection.name(),
		target,
		_conditions_str(),
	]

func _to_string() -> String:
	return "%s -> %s (%s)" % [
		action.name(),
		target_selection.name(),
		_conditions_str(),
	]

func _conditions_str() -> String:
	var names := PackedStringArray()
	for c in effective_conditions():
		names.append(c.name())
	return ", ".join(names)
