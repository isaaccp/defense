extends Area2D

class_name HitboxComponent

@export_group("Required")
@export var action_scene: ActionScene
# Damage on hit.
@export var damage: int
# TODO: Implement something like:
# * If "damage" is positive, whether allies get hit.
# * If "damage" is negative (heal), whether enemies get hit.
@export var friendly_fire = false
# If hits > 0, emit signal when out of hits.
@export var hits: int

@export_group("Debug")
@export var hits_left: int

signal all_hits_used

func _ready():
	hits_left = hits
	
func _on_area_entered(area):
	var hurtbox = area as HurtboxComponent
	if not hurtbox:
		assert(false, "Unexpected hit area was not hurtbox")
	_process_hurtbox_entered(hurtbox)
	
func _process_hurtbox_entered(hurtbox: HurtboxComponent):
	if hits > 0 and hits_left == 0:
		return
	if friendly_fire:  # No checks needed.
		if hurtbox.can_handle_collision():
			_process_hurtbox_hit(hurtbox)
	else:
		if action_scene.side_component.is_enemy(hurtbox.side_component):
			if hurtbox.can_handle_collision():
				_process_hurtbox_hit(hurtbox)

func _process_hurtbox_hit(hurtbox: HurtboxComponent):
	hurtbox.handle_collision(damage)
	if hits > 0:
		hits_left -= 1
		if hits_left == 0:
			all_hits_used.emit()
