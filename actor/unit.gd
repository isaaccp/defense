@tool
extends Actor

## An Actor that is considered a Unit in the game.
## It must have:
## * a DeathHandlerComponent
## * a BehaviorComponent
class_name Unit

# Optional for now, used for enemies.
@export var config: UnitConfig

signal died

func _ready():
	if Engine.is_editor_hint():
		return
	if config:
		visual_scale = config.visual_scale
	var death_handler_component: DeathHandlerComponent = get_component_or_die(DeathHandlerComponent)
	death_handler_component.died.connect(_on_died)

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
	_missing_component_warning(warnings, VitalsComponent)
	return warnings

func _missing_component_warning(warnings: PackedStringArray, component_class: Object):
	var component = get_component_or_null(component_class)
	if not component:
		warnings.append("Missing expected component: %s" % component_class.component)
