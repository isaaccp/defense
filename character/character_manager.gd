extends RefCounted

class_name CharacterManager

static var character_scene = preload("res://character/character.tscn")

static func available_characters() -> Array:
	return [Enum.CharacterId.KNIGHT]

static func character_name(id: Enum.CharacterId) -> String:
	return Enum.CharacterId.keys()[id].capitalize()

static func description(id: Enum.CharacterId) -> String:
	return "TODO"

static func make_character(game_state: GameplayCharacter) -> Character:
	var character = character_scene.instantiate() as Character
	character.id = game_state.character_id
	var persistent_game_state = Component.get_persistent_game_state_component_or_die(character)
	persistent_game_state.state = game_state
	return character
