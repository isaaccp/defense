extends Resource

class_name GameplayCharacter

@export_group("Debug")
@export var character_id: Enum.CharacterId
@export var peer_id: int
@export var behavior: Behavior
@export var skill_tree_state: SkillTreeState

static func make(character_id: Enum.CharacterId, peer_id: int = 1,
		behavior: Behavior = Behavior.new(),
		skill_tree_state: SkillTreeState = SkillTreeState.new()):
	var gameplay_character = GameplayCharacter.new()
	gameplay_character.character_id = character_id
	gameplay_character.peer_id = peer_id
	gameplay_character.behavior = behavior
	gameplay_character.skill_tree_state = skill_tree_state
	return gameplay_character 
