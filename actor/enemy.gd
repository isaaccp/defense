@tool
extends Unit

class_name Enemy

signal selected(enemy: Enemy)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	var mouse_event = event as InputEventMouseButton
	if not mouse_event:
		return
	if mouse_event.button_index == 1:
		# Current status: works, but scale of viewport is all off and also
		# this selection is based on the collission shape used for moving, so
		# you have to click on the feet to highlight. Maybe we need an extra
		# collission shape just for this or otherwise maybe when paused we
		# draw the feet shapes somehow and highlight them when over them, so
		# you can easily see what's up.
		print("selected %s" % actor_name)
		selected.emit(self)

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
	var character_body_component = get_component_or_null(CharacterBodyComponent)
	if not character_body_component:
		warnings.append("CharacterBodyComponent is required")
	return warnings
