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
}

@export var name: StringName
@export var effect_types: Array[EffectType]
@export var effect_script: GDScript

func _to_string():
	var effect_type_strings = effect_types.map(func(x): return EffectType.keys()[x].capitalize())
	return "%s\n[%s]" % [name, ",".join(effect_type_strings)]
