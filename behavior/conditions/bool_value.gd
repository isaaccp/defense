extends Resource

class_name BoolValue

@export var defined: bool = false
@export var value: bool = false

static func make(val: bool) -> BoolValue:
	var value = BoolValue.new()
	value.set_value(val)
	return value

func set_value(val: bool):
	value = val
	defined = true
