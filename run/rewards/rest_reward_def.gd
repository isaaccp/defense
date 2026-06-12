@tool
extends RewardDef

class_name RestRewardDef

## Fraction of max HP restored to each living party character.
@export_range(0.0, 1.0, 0.05) var heal_fraction: float = 0.3

func apply_and_get_outcome(_relic_library: RelicLibrary, gameplay_characters: Array[GameplayCharacter], ctx: RewardApplyContext) -> String:
	var lines: PackedStringArray = []
	var deltas: Dictionary[GameplayCharacter, int] = {}
	for gc in gameplay_characters:
		var max_hp := gc.attributes.health
		var heal_amount := int(round(max_hp * heal_fraction))
		var prev := gc.health
		gc.health = min(prev + heal_amount, max_hp)
		var actual: int = gc.health - prev
		if actual > 0:
			deltas[gc] = actual
		lines.append("%s: %d → %d" % [gc.name, prev, gc.health])
	ctx.flash_hp_floaters(deltas)
	return "\n".join(lines)
