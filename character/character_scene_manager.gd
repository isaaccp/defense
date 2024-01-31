@tool
extends Object

class_name CharacterSceneManager

const character_scenes = {
	Enum.CharacterSceneId.KNIGHT: preload("res://character/character.tscn"),
	Enum.CharacterSceneId.WIZARD: preload("res://character/wizard/wizard.tscn"),
	Enum.CharacterSceneId.CLERIC: preload("res://character/cleric/cleric.tscn"),
	Enum.CharacterSceneId.ROGUE: preload("res://character/rogue/rogue.tscn"),
}

static func get_character_scene(scene_id: Enum.CharacterSceneId) -> PackedScene:
	assert(scene_id in character_scenes)
	return character_scenes[scene_id]

static func make(gameplay_character: GameplayCharacter) -> Character:
	var scene = CharacterSceneManager.get_character_scene(gameplay_character.scene_id)
	var character = scene.instantiate() as Character
	character.actor_name = gameplay_character.name
	var persistent_game_state = Component.get_persistent_game_state_component_or_die(character)
	persistent_game_state.state = gameplay_character
	var health_component = HealthComponent.get_or_die(character)
	health_component.initial_health = gameplay_character.health
	return character
