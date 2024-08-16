@tool
extends Actor

## An Actor that is considered a Unit in the game.
## It must have:
## * a HealthComponent
## * a BehaviorComponent
class_name Unit

signal died

func _ready():
	if Engine.is_editor_hint():
		return
	var health_component = HealthComponent.get_or_die(self)
	health_component.died.connect(_on_died)

## Makes the Unit stay idle.
func force_idle(idle: bool = true):
	var behavior = BehaviorComponent.get_or_die(self)
	behavior.force_idle(idle)

func _on_died():
	died.emit()
	destroyed = true

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	_missing_component_warning(warnings, BehaviorComponent)
	_missing_component_warning(warnings, HealthComponent)
	return warnings

func _missing_component_warning(warnings: PackedStringArray, component_class: Object):
	var component = get_component_or_null(component_class)
	if not component:
		warnings.append("Missing expected component: %s" % component_class.component)
