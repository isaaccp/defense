extends SelfConditionEvaluator

class_name AoeUnitCountConditionBase

func evaluate() -> bool:
	if not action:
		push_error("%s: rule has no action wired to the evaluator" % def.skill_name)
		return false
	if action.def.aoe_placement == ActionDef.AoePlacement.NONE:
		push_error("%s used with non-AoE action '%s'" % [def.skill_name, action.def.name()])
		return false
	if not side_component:
		return false
	var placement := AoeTargetingHelper.best_placement(actor, action, side_component, is_ally())
	var threshold: int = def.params.int_value.value
	var op: SkillParams.CmpOp = def.params.cmp
	match op:
		SkillParams.CmpOp.LT: return placement.count < threshold
		SkillParams.CmpOp.LE: return placement.count <= threshold
		SkillParams.CmpOp.EQ: return placement.count == threshold
		SkillParams.CmpOp.GE: return placement.count >= threshold
		SkillParams.CmpOp.GT: return placement.count > threshold
	return false

func is_ally() -> bool:
	assert(false, "Must be implemented by subclass")
	return false
