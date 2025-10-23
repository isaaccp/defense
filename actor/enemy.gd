@tool
extends Unit

class_name Enemy

signal selected(enemy: Enemy)

func _ready():
	super()
	# TODO: Clean this up a bit. Likely make the top level CollisionShape2D a component.
	var config_component = get_node_or_null('ConfigComponent') as ConfigComponent
	if config_component:
		var config = config_component.config as EnemyConfig
		assert(config)
		actor_name = config.name
		var collision_shape_2d = $CollisionShape2D
		collision_shape_2d.shape = config.collision_shape
	$PickableComponent.selected.connect(selected.emit)

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	var config_component = get_component_or_null(ConfigComponent) as ConfigComponent
	if config_component:
		var enemy_config = config_component.config as EnemyConfig
		if not enemy_config:
			warnings.append("ConfigComponent config is not set or is not an EnemyConfig")
			return
		if enemy_config.name == '':
			warnings.append("EnemyConfig doesn't have name set")
		if not enemy_config.attributes_component_config:
			warnings.append("EnemyConfig doesn't have attributes_component_config set")
		# ...
		return
	var attributes_component = AttributesComponent.get_or_null(self)
	if not attributes_component:
		warnings.append("AttributesComponent is required")
	elif not attributes_component.base_attributes:
		warnings.append("AttributesComponent in Enemy needs to set base_attributes")
	var behavior_component = BehaviorComponent.get_or_null(self)
	if not behavior_component:
		warnings.append("BehaviorComponent is required")
		if not behavior_component.stored_behavior:
			warnings.append("BehaviorComponent in Enemy needs to set stored_behavior")
	var character_body_component = get_component_or_null(CharacterBodyComponent)
	if not character_body_component:
		warnings.append("CharacterBodyComponent is required")
	return warnings
