extends RefCounted

class_name TestUtils

static func set_character_behavior(character: Node2D, behavior: Behavior):
	var persistent_state = Component.get_persistent_game_state_component_or_die(character)
	persistent_state.state.behavior = behavior
