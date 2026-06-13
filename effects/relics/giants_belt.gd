extends Effect

func modify_attributes(attributes: Attributes) -> void:
	attributes.health += 30
	attributes.speed *= 0.85
