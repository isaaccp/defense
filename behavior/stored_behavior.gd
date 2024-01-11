@tool
extends Resource

class_name StoredBehavior

@export var stored_rules: Array[RuleDef]

# When behavior is set through editor/etc, we don't write (well, we do for now,
# but we want to change it) the full skill definition, but just RuleSkillDefs.
# From there we can create the full instance using the SkillManager.
func restore() -> Behavior:
	var behavior = Behavior.new()
	for stored_rule in stored_rules:
		var rule = SkillManager.restore_rule(stored_rule)
		behavior.rules.append(rule)
	return behavior

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
	# TODO: Fix and uncomment when we network again.
	#for serialized_rule in data:
		#var rule = Rule.make(
			#SkillManager.make_target_selection_instance(serialized_rule.target),
			#SkillManager.make_action_instance(serialized_rule.action)
		#)
		#behavior.rules.append(rule)
	return behavior

func _to_string() -> String:
	var result = ""
	for stored_rule in stored_rules:
		result += "%s\n" % str(stored_rule)
	return result
