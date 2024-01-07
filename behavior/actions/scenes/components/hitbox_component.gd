extends Area2D

class_name HitboxComponent

const component = &"HitboxComponent"

@export_group("Required")
@export var action_scene: ActionScene
# Whether it's a heal.
# It's just use to make sure that healing doesn't emit positive damage.
@export var is_heal = false
@export var hit_effect: HitEffect
# Damage on hit.
@export var damage: int
# Status on hit.
@export var status: StatusDef.Id
@export var status_duration: float
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
	assert(hit_effect.damage < 0 == is_heal)
	hit_effect.action_name = action_scene.action_def.skill_name
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

func _damage_str(adjusted_damage: int) -> String:
	if not damage:
		return ""
	var hit_type = "healed" if is_heal else "hit"
	var abs_damage = abs(damage)
	var abs_adjusted_damage = abs(adjusted_damage)
	var damage_str = (
		str(abs_adjusted_damage) if abs_adjusted_damage == abs_damage
		else "[hint=%d (base) * %0.1f (mult)]%d[/hint]" % [abs_damage, action_scene.attributes_component.damage_multiplier, abs_adjusted_damage]
	)
	return "%s for %s" % [hit_type, damage_str]

func _status_str() -> String:
	if status == StatusDef.Id.UNSPECIFIED:
		return ""
	return "applied %s (%0.1fs)" % [StatusDef.name(status), status_duration]

func _process_hurtbox_hit(hurtbox: HurtboxComponent):
	hit_effect.damage_multiplier = action_scene.attributes_component.damage_multiplier
	var adjusted_damage = hit_effect.adjusted_damage()
	hurtbox.handle_collision(action_scene.owner_name, action_scene.name, hit_effect)

	action_scene.action_scene_log("%s %s" % [hurtbox.get_parent().name, hit_effect.log_text()])
	if hits > 0:
		hits_left -= 1
		if hits_left == 0:
			all_hits_used.emit()
