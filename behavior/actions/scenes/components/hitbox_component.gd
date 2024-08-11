extends Area2D

class_name HitboxComponent

const component = &"HitboxComponent"

@export_group("Required")
## Whether it's a heal/friendly.
## It's just used to make sure that healing doesn't emit positive damage and
## to determine if it's friendly or not (should probably be renamed to
## is_friendly).
@export var is_heal = false
@export var hit_effect: HitEffect
## * If not is_heal, whether allies get hit.
## * If is_heal, whether enemies get hit.
@export var friendly_fire = false
## If hits > 0, emit signal when out of hits.
@export var hits: int

@export_group("Optional")
## If > 0, each target will be hit at most these many times.
## This doesn't affect 'hits'. E.g. if 'hits' is 2, then setting
## 'max_hits_per_target' to 1 just means that the attack can hit twice but
## it must hit different targets.
@export var max_hits_per_target = 0
## If set, this will only collide against desired target.
@export var hit_only_target = false
## Provides access to target, only used if "hit_only_target" is true.
@export var target_component: TargetComponent

@export_group("Debug")
@export var hits_left: int

# Set through initialize.
var owner_name: String
var action_def: ActionDef
var attributes: Attributes
var side_component: SideComponent
var logging_component: LoggingComponent
var effect_actuator_component: EffectActuatorComponent

var collision_shape: CollisionShape2D
var running = false
var hits_per_target: Dictionary

signal all_hits_used
signal hit(hit_effect: HitEffect, hit_result: HitResult)

func _ready():
	collision_shape = $CollisionShape2D
	assert(collision_shape)
	collision_shape.disabled = true

func initialize(owner_name: String, action_def: ActionDef, attributes: Attributes, side_component: SideComponent, logging_component: LoggingComponent, effect_actuator_component: EffectActuatorComponent):
	self.owner_name = owner_name
	self.action_def = action_def
	self.attributes = attributes
	self.side_component = side_component
	self.logging_component = logging_component
	self.effect_actuator_component = effect_actuator_component

func run():
	if running:
		assert(false, "run() call twice")
	collision_shape.disabled = false
	running = true
	assert((hit_effect.damage == 0) || (hit_effect.damage < 0 == is_heal))
	hit_effect.action_name = action_def.skill_name
	hit_effect.attack_type = action_def.attack_type
	hits_left = hits

func _on_area_entered(area):
	var hurtbox = area as HurtboxComponent
	if not hurtbox:
		assert(false, "Unexpected hit area was not hurtbox")
	_process_hurtbox_entered(hurtbox)

func _process_hurtbox_entered(hurtbox: HurtboxComponent):
	if hits > 0 and hits_left == 0:
		return
	if hit_only_target:
		var actor = hurtbox.get_parent()
		if actor != target_component.action_target.target.actor:
			return
	var process: bool
	if friendly_fire:
		process = true
	else:
		if not is_heal:
			process = side_component.is_enemy(hurtbox.side_component)
		else:
			process = side_component.is_ally(hurtbox.side_component)
	if process:
		if hurtbox.can_handle_collision():
			if max_hits_per_target > 0:
				if not hurtbox in hits_per_target:
					hits_per_target[hurtbox] = 0
				## Already reached max hits for this target, skip.
				if hits_per_target[hurtbox] >= max_hits_per_target:
					return
				else:
					# At this point we'll always run _process_hurtbox_hit,
					# so we can update this already.
					hits_per_target[hurtbox] += 1
			if hits > 0:
				hits_left -= 1
				if hits_left == 0:
					all_hits_used.emit()
			_process_hurtbox_hit(hurtbox)

func _damage_str(adjusted_damage: int) -> String:
	if not hit_effect.damage:
		return ""
	var hit_type = "healed" if is_heal else "hit"
	var abs_damage = abs(hit_effect.damage)
	var abs_adjusted_damage = abs(adjusted_damage)
	var damage_str = (
		str(abs_adjusted_damage) if abs_adjusted_damage == abs_damage
		else "[hint=%d (base) * %0.1f (mult)]%d[/hint]" % [abs_damage, attributes.damage_multiplier, abs_adjusted_damage]
	)
	return "%s for %s" % [hit_type, damage_str]

func _status_str() -> String:
	if not hit_effect.status:
		return ""
	return "applied %s (%0.1fs)" % [hit_effect.status, hit_effect.status_duration]

func _process_hurtbox_hit(hurtbox: HurtboxComponent):
	hit_effect.damage_multiplier = attributes.damage_multiplier
	var effective_hit_effect = effect_actuator_component.modified_hit_effect(hit_effect)
	var hit_result = hurtbox.handle_collision(owner_name, get_parent().actor_name, effective_hit_effect)

	hit.emit(effective_hit_effect, hit_result)

	# TODO: Could update log to also include hit_result information, although alternatively we can
	# not include it and make enemy logs viewable, in which case you could see it there.

	hitbox_log(
		"%s %s" % [hurtbox.get_parent().actor_name, effective_hit_effect.log_text()],
		hit_result.stats_update()
	)

func hitbox_log(message: String, stats_update: Array[Stat]):
	if not logging_component:
		return
	var full_message = "%s: %s" % [get_parent().actor_name, message]
	logging_component.add_log_entry(LoggingComponent.LogType.ACTION, full_message, stats_update)

static func get_or_null(node: Node) -> HitboxComponent:
	return Component.get_or_null(node, component) as HitboxComponent

static func get_or_die(node: Node) -> HitboxComponent:
	var component = get_or_null(node)
	assert(component)
	return component
