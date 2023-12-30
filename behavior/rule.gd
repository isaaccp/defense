extends Resource

class_name Rule

@export var target_selection: TargetSelectionDef
@export var action: ActionDef

func _to_string() -> String:
	return "Target Selection: %s Action: %s" % [
		target_selection,
		action,
	]
