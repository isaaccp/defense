extends Effect

# +0.5 focus regen per second. Modest but reliable; complements any
# focus-hungry kit.

const FOCUS_REGEN_BONUS: float = 0.5

func modify_attributes(base_attributes: Attributes) -> void:
	base_attributes.focus_regen += FOCUS_REGEN_BONUS
