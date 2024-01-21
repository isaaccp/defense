@tool
extends Unit

class_name Enemy

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	var attributes_component = AttributesComponent.get_or_null(self)
	if not attributes_component:
		warnings.append("AttributesComponent is required")
	elif not attributes_component.base_attributes:
		warnings.append("AttributesComponent needs to set base_attributes")
	return warnings
