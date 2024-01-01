extends Resource

class_name GameplayCharacter

@export var character_id: Enum.CharacterId
@export var peer_id: int
@export var behavior: Behavior

static func make(character_id: Enum.CharacterId, peer_id: int = 1, behavior: Behavior = Behavior.new()):
	var gameplay_character = GameplayCharacter.new()
	gameplay_character.character_id = character_id
	gameplay_character.peer_id = peer_id
	gameplay_character.behavior = behavior
	return gameplay_character 
