extends Node2D

class_name ActionScene

@export_group("Optional")
# Optional, but hurtbox_hit won't happen without it.
@export var hitbox_component: HitboxComponent

# From Body components.
var side_component: SideComponent

func initialize(side_component_: SideComponent):
	side_component = side_component_
