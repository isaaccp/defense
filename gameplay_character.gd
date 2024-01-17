extends Resource

class_name GameplayCharacter


@export_group("Character Definition")
## Character name.
@export var name: String
## A brief description of the character kit.
@export var starting_kit: String
## Scene to use for the character in-game.
@export var scene_id: Enum.CharacterSceneId
## Multiline description of character, backstory, etc.
@export_multiline var description: String
## Default behavior for this character, can be left unset.
@export var behavior: StoredBehavior
## Initial acquired skills.
@export var acquired_skills: SkillTreeState
## Attributes.
@export var attributes: Attributes

# Those could be put in a separate resource for grouping.
@export_group("Extra Save Data")
## Used to track health across levels, on save, etc.
@export var health: int
## Used to track XP across levels, on save, etc.
@export var xp: int

var peer_id: int
var actor: Character

func use_xp(amount: int) -> void:
	assert(xp >= amount, "Tried to use more XP than possible")
	xp -= amount

func has_xp(amount: int) -> bool:
	return xp >= amount

func grant_xp(amount: int) -> void:
	xp += amount

func after_level_heal():
	var new_health = health + attributes.health * attributes.recovery
	health = min(new_health, attributes.health)

func make_character_body() -> Character:
	var scene = CharacterSceneManager.get_character_scene(scene_id)
	actor = scene.instantiate() as Character
	actor.actor_name = name
	var persistent_game_state = Component.get_persistent_game_state_component_or_die(actor)
	persistent_game_state.state = self
	return actor
