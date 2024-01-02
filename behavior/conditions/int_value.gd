extends Resource

class_name IntValue

@export var defined: bool = false
@export var value: int

static func make(val: int) -> IntValue:
	var value = IntValue.new()
	value.set_value(val)
	return value

func set_value(val: int):
	value = val
	defined = true
