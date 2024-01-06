@tool
extends Control
class_name ProgrammingUI

@export_category("Testing")
## Used for F6 debug runs.
@export var test_character: GameplayCharacter

var character: Character
@onready var script_tree: ScriptTree = %Script

signal canceled
signal saved(behavior: Behavior)

func _ready():
	# Only when launched with F6.
	if get_parent() == get_tree().root:
		# So it works as a standalone scene for easy testing.
		if test_character:
			initialize(test_character.make_character_body())
		canceled.connect(get_tree().quit)

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
		%Title.text = "Configuring behavior for %s" % character.actor_name
		var behavior_component = Component.get_behavior_component_or_die(character)
		if behavior_component.behavior:
			script_tree.load_behavior(behavior_component.behavior)

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
