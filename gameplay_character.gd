extends Resource

class_name GameplayCharacter

@export var character_id: Enum.CharacterId
@export var peer_id: int
@export var behavior: Behavior

# Used for testing for now.
static func make_gameplay_character(character_id: Enum.CharacterId):
	var character = GameplayCharacter.new()
	character.character_id = character_id
	return character 
