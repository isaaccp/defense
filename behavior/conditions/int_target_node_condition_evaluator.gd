extends TargetNodeConditionEvaluator

class_name IntTargetNodeConditionEvaluator

# Set to true if get_value fails. Evaluator will
# then return false.
var get_value_failed = false

func get_value(node: Node2D) -> int:
	assert(false, "Must be implemented")
	return 0

func _comparison(value: int) -> bool:
	if get_value_failed:
		return false
	match def.params.cmp:
		ConditionParams.CmpOp.LT:
			return value < def.params.int_value.value
		ConditionParams.CmpOp.LE:
			return value <= def.params.int_value.value
		ConditionParams.CmpOp.EQ:
			return value == def.params.int_value.value
		ConditionParams.CmpOp.GE:
			return value >= def.params.int_value.value
		ConditionParams.CmpOp.GT:
			return value > def.params.int_value.value
		_:
			assert(false, "Unexpected CmpOp")
	assert(false, "Unreachable")
	return false

func evaluate(node: Node2D) -> bool:
	var value = get_value(node)
	return _comparison(value)
