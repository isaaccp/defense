@tool
extends Control

class_name ProgrammingUI

var character: Character
@onready var script_tree: ScriptTree = %Script

signal canceled
signal saved(behavior: Behavior)

func initialize(character_: Character):
	assert(is_inside_tree(), "Needs to be called inside tree")
	character = character_
	var skill_manager = Component.get_skill_manager_component_or_die(character)
	%Toolbox.initialize(
		skill_manager.target_types(),
		skill_manager.actions(),
		skill_manager.conditions(),
	)
	if is_instance_valid(character):
		%Title.text = "Configuring behavior for %s" % character.short_name()
		if character.behavior:
			script_tree.load_behavior(character.behavior)

func editor_initialize(b: Behavior):
	assert(is_inside_tree(), "Needs to be called inside tree")
	if not b:
		%Title.text = "Inspect a behavior resource to edit..."
		%SaveButton.disabled = true
		return
	%Toolbox.initialize(
		TargetSelectionManager.all_target_selections(),
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
