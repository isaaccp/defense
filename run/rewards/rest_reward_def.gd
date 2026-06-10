@tool
extends RewardDef

class_name RestRewardDef

## Fraction of max HP restored to each living party character.
@export_range(0.0, 1.0, 0.05) var heal_fraction: float = 0.3

func apply_and_get_outcome(run_save_state: RunSaveState, screen) -> String:
	var lines: PackedStringArray = []
	for gc in run_save_state.gameplay_characters:
		var max_hp := gc.attributes.health
		var heal_amount := int(round(max_hp * heal_fraction))
		var prev := gc.health
		gc.health = min(prev + heal_amount, max_hp)
		lines.append("%s: %d → %d" % [gc.name, prev, gc.health])
	if screen and screen.has_method("refresh_character_cards"):
		screen.refresh_character_cards()
	return "\n".join(lines)
