@tool
extends Actor

## An Actor that is considered a Unit in the game.
## It must have:
## * a HealthComponent
## * a BehaviorComponent
class_name Unit

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	_missing_component_warning(warnings, BehaviorComponent)
	_missing_component_warning(warnings, HealthComponent)
	return warnings

func _missing_component_warning(warnings: PackedStringArray, component_class: Object):
	var component = component_class.get_or_null(self)
	if not component:
		warnings.append("Missing expected component: %s" % component_class.component)
