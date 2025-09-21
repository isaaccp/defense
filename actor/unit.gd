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
	var vitals_component = get_component_or_die(VitalsComponent)
	vitals_component.vital_depleted.connect(_on_vital_depleted)

## Makes the Unit stay idle.
func force_idle(idle: bool = true):
	var behavior = BehaviorComponent.get_or_die(self)
	behavior.force_idle(idle)

func _on_vital_depleted(vital_type: VitalsComponent.VitalType):
	if vital_type == VitalsComponent.VitalType.HEALTH:
		died.emit()
		destroyed = true

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	_missing_component_warning(warnings, BehaviorComponent)
	_missing_component_warning(warnings, VitalsComponent)
	return warnings

func _missing_component_warning(warnings: PackedStringArray, component_class: Object):
	var component = get_component_or_null(component_class)
	if not component:
		warnings.append("Missing expected component: %s" % component_class.component)
