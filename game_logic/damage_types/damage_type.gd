extends Resource

class_name DamageType

enum MacroType {
	UNSPECIFIED,
	## Slashing, etc.
	PHYSICAL,
	## Pure magic.
	ARCANE,
	## Elemental (magic or otherwise).
	ELEMENTAL,
}

@export var name: StringName
@export var macro_type: MacroType
