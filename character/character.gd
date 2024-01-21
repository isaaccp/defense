extends Unit

class_name Character

@export_group("debug")
@export var idx: int
@export var peer_id: int

static func make(gameplay_character: GameplayCharacter) -> Character:
	var scene = CharacterSceneManager.get_character_scene(gameplay_character.scene_id)
	var character = scene.instantiate() as Character
	character.actor_name = gameplay_character.name
	var persistent_game_state = Component.get_persistent_game_state_component_or_die(character)
	persistent_game_state.state = gameplay_character
	return character
