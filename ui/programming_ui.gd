@tool
extends Control
class_name ProgrammingUI

@export_category("Testing")
## Used for F6 debug runs.
@export var test_character: GameplayCharacter

var character: GameplayCharacter
@onready var script_tree: ScriptTree = %Script

signal canceled
signal saved(behavior: Behavior)

func _ready():
	# Only when launched with F6.
	if get_parent() == get_tree().root:
		# So it works as a standalone scene for easy testing.
		if test_character:
			initialize(test_character)
		canceled.connect(get_tree().quit)

func initialize(character_: GameplayCharacter):
	assert(is_inside_tree(), "Needs to be called inside tree")
	character = character_
	%Toolbox.initialize(
		character.skill_tree_state.acquired_target_selections,
		character.skill_tree_state.acquired_actions,
		character.skill_tree_state.acquired_conditions,
	)
	if is_instance_valid(character):
		%Title.text = "Configuring behavior for %s" % character.name
		script_tree.load_behavior(character.behavior)

func editor_initialize(b: Behavior):
	assert(is_inside_tree(), "Needs to be called inside tree")
	if not b:
		%Title.text = "Inspect a behavior resource to edit..."
		%SaveButton.disabled = true
		return
	%Toolbox.initialize(
		SkillManager.all_target_selections(),
		SkillManager.all_actions(),
		SkillManager.all_conditions(),
	)
	%Title.text = "Editing %s" % b.resource_path
	script_tree.load_behavior(b)
	%SaveButton.disabled = false

func _on_save_button_pressed():
	saved.emit(script_tree.get_behavior())

func _on_cancel_button_pressed():
	canceled.emit()
