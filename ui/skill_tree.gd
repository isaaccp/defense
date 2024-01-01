extends Control

var skill_tree_state: SkillTreeState

func initialize(character: GameplayCharacter):
	skill_tree_state = character.skill_tree_state
