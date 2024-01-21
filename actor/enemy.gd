@tool
extends Unit

class_name Enemy

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	var attributes_component = AttributesComponent.get_or_null(self)
	if not attributes_component:
		warnings.append("AttributesComponent is required")
	elif not attributes_component.base_attributes:
		warnings.append("AttributesComponent in Enemy needs to set base_attributes")
	var behavior_component = BehaviorComponent.get_or_null(self)
	if not behavior_component:
		warnings.append("BehaviorComponent is required")
		if not behavior_component.stored_behavior:
			warnings.append("BehaviorComponent in Enemy needs to set stored_behavior")
	return warnings
