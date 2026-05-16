extends Effect

# Wizard class relic. Boosts base focus regen — "wizard waits and casts."
# Implementation: modifies the attributes hook so it stacks correctly with
# any other regen modifiers from statuses/other relics.

const FOCUS_REGEN_BONUS: float = 1.0

func modify_attributes(base_attributes: Attributes) -> void:
	base_attributes.focus_regen += FOCUS_REGEN_BONUS
