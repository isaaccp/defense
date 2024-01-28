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
}

@export var name: StringName
@export var effect_types: Array[EffectType]
@export var effect_script: GDScript
