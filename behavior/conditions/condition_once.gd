extends AnyConditionEvaluator

var first = true

func evaluate():
	if first:
		first = false
		return true
	return false
