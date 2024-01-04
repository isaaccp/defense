extends Area2D

class_name HitboxComponent

const component = &"HitboxComponent"

@export_group("Required")
@export var action_scene: ActionScene
# Whether it's a heal.
# It's just use to make sure that healing doesn't emit positive damage.
@export var is_heal = false
# Damage on hit.
@export var damage: int
# TODO: Implement something like:
# * If not is_heal, whether allies get hit.
# * If is_heal, whether enemies get hit.
@export var friendly_fire = false
# If hits > 0, emit signal when out of hits.
@export var hits: int

@export_group("Debug")
@export var hits_left: int

signal all_hits_used

func _ready():
	assert(damage < 0 == is_heal)
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
		var process: bool
		if not is_heal:
			process = action_scene.side_component.is_enemy(hurtbox.side_component)
		else:
			process = action_scene.side_component.is_ally(hurtbox.side_component)
		if process:
			if hurtbox.can_handle_collision():
				_process_hurtbox_hit(hurtbox)

func _process_hurtbox_hit(hurtbox: HurtboxComponent):
	var adjusted_damage = round(float(damage) * action_scene.attributes_component.damage_multiplier)
	hurtbox.handle_collision(action_scene.owner_name, action_scene.name, adjusted_damage)
	var hit_type = "healed" if is_heal else "hit"
	var damage_str = (
		str(adjusted_damage) if adjusted_damage == damage
		else "[hint=%d (base) * %0.1f (mult)]%d[/hint]" % [damage, action_scene.attributes_component.damage_multiplier, adjusted_damage]
	)
	action_scene.action_scene_log("%s %s for %s damage" % [hit_type, hurtbox.get_parent().name, damage_str])
	if hits > 0:
		hits_left -= 1
		if hits_left == 0:
			all_hits_used.emit()
