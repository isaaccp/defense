@tool
extends Resource

class_name UnitConfig

## Collision shape for movement collisions. TODO: This should be a component.
@export var collision_shape: Shape2D
@export var animation_component_config: AnimationComponentConfig
@export var hurtbox_component_config: HurtboxComponentConfig
