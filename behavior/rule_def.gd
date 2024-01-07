extends Resource

class_name RuleDef

@export var target_selection: RuleSkillDef
@export var action: RuleSkillDef
@export var condition: RuleSkillDef

# TODO: FIXME
#func _to_string() -> String:
	#return "%s -> %s (%s)" % [
		#action.name(),
		#target_selection.name(),
		#condition.name(),
	#]

static func make(target_selection: RuleSkillDef, action: RuleSkillDef, condition: RuleSkillDef = RuleSkillDef.make_condition(ConditionDef.Id.ALWAYS)) -> RuleDef:
	var rule = RuleDef.new()
	rule.target_selection = target_selection
	rule.action = action
	rule.condition = condition
	return rule
