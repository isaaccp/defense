extends AnyConditionEvaluator

var count = 0

func evaluate():
	count += 1
	return count <= def.params.int_value.value
