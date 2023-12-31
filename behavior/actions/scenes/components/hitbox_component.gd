extends Area2D

class_name HitboxComponent

@export_group("Required")
@export var damage: int
@export var friendly_fire = false
@export var action_scene: ActionScene

signal hurtbox_hit(hurtbox: HurtboxComponent)

func _on_area_entered(area):
	var hurtbox = area as HurtboxComponent
	if not hurtbox:
		assert(false, "Unexpected hit area was not hurtbox")
	_process_hit(hurtbox)
	
func _process_hit(hurtbox: HurtboxComponent):
	if friendly_fire:  # No checks needed.
		if hurtbox.can_handle_collision():
			hurtbox.handle_collision(damage)
	else:
		if action_scene.side_component.is_enemy(hurtbox.side_component):
			if hurtbox.can_handle_collision():
				hurtbox.handle_collision(damage)
