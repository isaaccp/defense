extends RefCounted

class_name CharacterManager

static var character_scene = preload("res://character/character.tscn")

static var character_specs = {
	Enum.CharacterId.KNIGHT: preload("res://character/knight/knight_spec.tscn"),
}

static func available_characters() -> Array:
	return character_specs.keys()

static func character_name(id: Enum.CharacterId) -> String:
	return Enum.CharacterId.keys()[id].capitalize()

static func make_character_spec(id: Enum.CharacterId) -> CharacterSpec:
	return character_specs[id].instantiate() as CharacterSpec

static func description(id: Enum.CharacterId) -> String:
	var spec = make_character_spec(id)
	return "TODO"


static func make_character(id: Enum.CharacterId) -> Character:
	var character = character_scene.instantiate() as Character
	character.id = id
	character.spec = make_character_spec(id)
	character.add_child(character.spec)
	return character
