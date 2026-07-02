@tool
extends Unit

class_name Enemy

signal selected(enemy: Enemy)

func _ready():
	super()
	
	if config:
		var enemy_config = config as EnemyConfig
		assert(enemy_config)
		actor_name = enemy_config.name
		var collision_shape_2d = $CollisionShape2D
		collision_shape_2d.shape = enemy_config.collision_shape
		if visual_scale != 1.0:
			self.scale = Vector2(visual_scale, visual_scale)
	$PickableComponent.selected.connect(selected.emit)

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	# TODO: Some of those can now be provided through config instead.
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
