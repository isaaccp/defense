extends Effect

# Wizard starting bonus relic. Extra max-focus headroom for burst casting.
# Combined with Meditation's +1.0/s regen, lets the wizard sustain multi-cast windows.

const FOCUS_MAX_BONUS: int = 30

func modify_attributes(base_attributes: Attributes) -> void:
	base_attributes.focus += FOCUS_MAX_BONUS
