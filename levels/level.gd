extends Node2D

@export var characters: Node2D
@export var starting_positions: Node

func initialize(character_selections: Array[Enum.CharacterId]):
	for i in character_selections.size():
		var character = CharacterManager.make_character(character_selections[i])
		character.position = starting_positions.get_child(i).position
		characters.add_child(character)
