@tool
extends Resource

class_name StoredBehavior

## Name. Needs to be set in order to store behavior in library.
@export var name: String
## Rules.
@export var stored_rules: Array[RuleDef]

func serialize() -> PackedByteArray:
	var data = []
	#for stored_rule in stored_rules:
		#var rule_dict = {
			#"target": rule.target_selection.skill_name,
			#"action": rule.action.skill_name,
		#}
		#data.append(rule_dict)
	return var_to_bytes(data)

static func deserialize(serialized_behavior: PackedByteArray) -> StoredBehavior:
	var behavior = StoredBehavior.new()
	var _data = bytes_to_var(serialized_behavior)
	# TODO: Implement when we network again.
	return behavior

func _to_string() -> String:
	var result = ""
	for stored_rule in stored_rules:
		result += "%s\n" % str(stored_rule)
	return result
