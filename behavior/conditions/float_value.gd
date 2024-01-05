extends Resource

class_name FloatValue

@export var defined: bool = false
@export var value: float

static func make(val: float) -> FloatValue:
	var value = FloatValue.new()
	value.set_value(val)
	return value

func set_value(val: float):
	value = val
	defined = true
