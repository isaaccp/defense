extends Area2D

class_name HurtboxComponent

@export_group("Required")
@export var side_component: SideComponent

@export_group("Optional")
# Optional as e.g. you may still want to have a hurtbox
# for things that can't be killed.
@export var health_component: HealthComponent

func can_handle_collision():
	return (not health_component) or health_component.health > 0
	
func handle_collision(damage: int):
	if health_component:
		health_component.damage(damage)
