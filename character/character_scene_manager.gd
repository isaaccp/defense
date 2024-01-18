extends Object

class_name CharacterSceneManager

const character_scenes = {
	Enum.CharacterSceneId.KNIGHT: preload("res://character/character.tscn"),
	Enum.CharacterSceneId.WIZARD: preload("res://character/wizard/wizard.tscn"),
}

static func get_character_scene(scene_id: Enum.CharacterSceneId) -> PackedScene:
	assert(scene_id in character_scenes)
	return character_scenes[scene_id]
