extends PositionConditionEvaluator

class_name FloatPositionConditionEvaluator

# Set to true if get_value fails. Evaluator will
# then return false.
var get_value_failed = false

func get_value(position: Vector2) -> float:
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

func evaluate(target: Vector2) -> bool:
	var value = get_value(target)
	return _comparison(value)
