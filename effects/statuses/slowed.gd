extends Effect

# Slowed: target moves at half speed. First speed-debuff status in the
# game — set up by Chilling Sphere (Wizard AoE) and meant to feed future
# status-combo conditions ("Has Status Slowed" etc.).

const SPEED_MULTIPLIER: float = 0.5

func modify_attributes(attributes: Attributes) -> void:
	attributes.speed *= SPEED_MULTIPLIER
