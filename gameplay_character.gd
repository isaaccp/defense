extends Resource

class_name GameplayCharacter

@export var character_id: Enum.CharacterId
@export var peer_id: int
@export var behavior: Behavior

static func make_gameplay_character(character_id: Enum.CharacterId):
	var gameplay_character = GameplayCharacter.new()
	gameplay_character.character_id = character_id
	return gameplay_character 
