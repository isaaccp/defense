extends Effect

# +20 max focus. Lets you cast more before running dry.

const FOCUS_MAX_BONUS: int = 20

func modify_attributes(base_attributes: Attributes) -> void:
	base_attributes.focus += FOCUS_MAX_BONUS
