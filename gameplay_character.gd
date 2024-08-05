@tool
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
## List of relics the character has.
@export var relics: Array[StringName]

var peer_id: int

func initialize(name: String, peer_id: int, behavior: StoredBehavior = null):
	self.name = name
	self.peer_id = peer_id
	health = attributes.health
	if behavior:
		self.behavior = behavior

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

func add_relic(relic_name: StringName):
	relics.append(relic_name)
