extends Resource

class_name RuleDef

@export var target_selection: RuleSkillDef
@export var action: RuleSkillDef
@export var condition: RuleSkillDef

const always = preload("res://skill_tree/conditions/always.tres")

# TODO: FIXME
#func _to_string() -> String:
	#return "%s -> %s (%s)" % [
		#action.name(),
		#target_selection.name(),
		#condition.name(),
	#]

static func make(target_selection: RuleSkillDef, action: RuleSkillDef, condition: RuleSkillDef = always.rule_skill_def()) -> RuleDef:
	var rule = RuleDef.new()
	rule.target_selection = target_selection
	rule.action = action
	rule.condition = condition
	return rule
