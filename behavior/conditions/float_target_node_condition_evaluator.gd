extends TargetNodeConditionEvaluator

class_name FloatTargetNodeConditionEvaluator

# Set to true if get_value fails. Evaluator will
# then return false.
var get_value_failed = false

func get_value(node: Node2D) -> float:
	assert(false, "Must be implemented")
	return 0

func _comparison(value: float) -> bool:
	if get_value_failed:
		return false
	match def.params.cmp:
		SkillParams.CmpOp.LT:
			return value < def.params.float_value.value
		SkillParams.CmpOp.LE:
			return value <= def.params.float_value.value
		SkillParams.CmpOp.EQ:
			return value == def.params.float_value.value
		SkillParams.CmpOp.GE:
			return value >= def.params.float_value.value
		SkillParams.CmpOp.GT:
			return value > def.params.float_value.value
		_:
			assert(false, "Unexpected CmpOp")
	assert(false, "Unreachable")
	return false

func evaluate(node: Node2D) -> bool:
	var value = get_value(node)
	return _comparison(value)
