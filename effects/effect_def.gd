extends Resource

class_name EffectDef

enum EffectType {
	UNSPECIFIED,
	## Effects that modify attributes.
	ATTRIBUTE,
	## Effects that modify HitEffect.
	HIT_EFFECT,
	## Effects that change ability to act.
	ABLE_TO_ACT,
	## Effects that modify action cooldown.
	ACTION_COOLDOWN,
	## Effects that react to the bearer taking damage. Fired AFTER damage is applied.
	## Implementer overrides Effect.on_damage_taken(damage_taken: int, attacker_name: String).
	ON_DAMAGE_TAKEN,
	## Effects that react to the bearer healing an ally. Fired AFTER the heal is applied.
	## Implementer overrides Effect.on_heal_applied(amount_healed: int, target_name: String).
	ON_HEAL_APPLIED,
	## Effects that react to the bearer killing an enemy. Fired when the kill is recorded.
	## Implementer overrides Effect.on_enemy_killed(victim_name: String).
	ON_ENEMY_KILLED,
	## Effects that modify the duration of incoming statuses.
	## Implementer overrides Effect.modified_incoming_status_duration(status_def: StatusDef, duration: float).
	MODIFIED_INCOMING_STATUS_DURATION,
}

@export var name: StringName
@export var effect_types: Array[EffectType]
@export var effect_script: GDScript

func _to_string():
	var effect_type_strings = effect_types.map(func(x): return EffectType.keys()[x].capitalize())
	return "%s\n[%s]" % [name, ",".join(effect_type_strings)]
