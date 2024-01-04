extends Resource

class_name GameplayCharacter

@export var name: String
@export var character_id: Enum.CharacterId
@export var behavior: Behavior
@export var skill_tree_state: SkillTreeState

@export_group("Debug")
@export var peer_id: int
@export var xp: int
# Total accummulated XP, for fun.
@export var total_xp: int

static func make(character_id: Enum.CharacterId, name: String = "", peer_id: int = 1,
		behavior: Behavior = Behavior.new(),
		skill_tree_state: SkillTreeState = SkillTreeState.new()):
	var gameplay_character = GameplayCharacter.new()
	gameplay_character.character_id = character_id
	if name.is_empty():
		gameplay_character.name = Enum.character_id_string(character_id)
	else:
		gameplay_character.name = name
	gameplay_character.peer_id = peer_id
	gameplay_character.behavior = behavior
	gameplay_character.skill_tree_state = skill_tree_state
	return gameplay_character

func use_xp(amount: int) -> void:
	assert(xp >= amount, "Tried to use more XP than possible")
	xp -= amount

func has_xp(amount: int) -> bool:
	return xp >= amount

func grant_xp(amount: int) -> void:
	xp += amount
	total_xp += amount
