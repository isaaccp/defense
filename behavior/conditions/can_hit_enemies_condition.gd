extends SelfConditionEvaluator

# True iff the best AoE placement (per AoeTargetingHelper) catches a number
# of enemies that satisfies {cmp} {int_value} — e.g. ">= 2 enemies in best
# AoE placement". Requires the rule's action to declare aoe_shape +
# aoe_placement.

func evaluate() -> bool:
	if not action:
		push_error("Can Hit Enemies: rule has no action wired to the evaluator")
		return false
	if action.def.aoe_placement == ActionDef.AoePlacement.NONE:
		push_error("Can Hit Enemies used with non-AoE action '%s'" % action.def.name())
		return false
	if not side_component:
		return false
	var placement := AoeTargetingHelper.best_placement(actor, action, side_component)
	var threshold: int = def.params.int_value.value
	var op: SkillParams.CmpOp = def.params.cmp
	match op:
		SkillParams.CmpOp.LT: return placement.count < threshold
		SkillParams.CmpOp.LE: return placement.count <= threshold
		SkillParams.CmpOp.EQ: return placement.count == threshold
		SkillParams.CmpOp.GE: return placement.count >= threshold
		SkillParams.CmpOp.GT: return placement.count > threshold
	return false
