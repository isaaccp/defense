extends Effect

# Warrior starting bonus relic. Passive in-combat HP regen.
# Tuned to be noticeably weaker than priest's Heal so active healing stays dominant.

const HEALTH_REGEN_BONUS: float = 1.0

func modify_attributes(base_attributes: Attributes) -> void:
	base_attributes.health_regen += HEALTH_REGEN_BONUS
