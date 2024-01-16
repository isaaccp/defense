extends Resource

class_name GameplayCharacter

@export var name: String
@export var starting_kit: String
@export var scene_id: Enum.CharacterSceneId
@export_multiline var description: String
@export var behavior: StoredBehavior
@export var acquired_skills: SkillTreeState

@export_group("Debug")
@export var peer_id: int
@export var xp: int
# Total accummulated XP, for fun.
@export var total_xp: int

var actor: Character

func use_xp(amount: int) -> void:
	assert(xp >= amount, "Tried to use more XP than possible")
	xp -= amount

func has_xp(amount: int) -> bool:
	return xp >= amount

func grant_xp(amount: int) -> void:
	xp += amount
	total_xp += amount

func make_character_body() -> Character:
	var scene = CharacterSceneManager.get_character_scene(scene_id)
	actor = scene.instantiate() as Character
	actor.actor_name = name
	var persistent_game_state = Component.get_persistent_game_state_component_or_die(actor)
	persistent_game_state.state = self
	return actor
