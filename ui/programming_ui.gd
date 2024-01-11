@tool
extends Control
class_name ProgrammingUI

@export_category("Testing")
## Used for F6 debug runs.
@export var test_character: GameplayCharacter

var _title_text: String
var _behavior: StoredBehavior
var _skills: SkillTreeState
var _save_disabled: bool

@onready var _script_tree = %Script as ScriptTree
@onready var _toolbox = %Toolbox as Toolbox

signal canceled
signal saved(behavior: StoredBehavior)

func initialize(character: GameplayCharacter):
	assert(is_instance_valid(character)) # TODO: Handle gracefully if needed.
	_title_text = "Configuring behavior for %s" % character.name
	_behavior = character.behavior
	_skills = character.skill_tree_state
	_save_disabled = false

func editor_initialize(b: StoredBehavior):
	_skills = SkillTreeState.new()
	_skills.full_acquired = true
	_skills.full_unlocked = true

	_behavior = b
	if b:
		_title_text = "Editing %s" % b.resource_path
		_save_disabled = false
	else:
		_title_text = "Inspect a behavior resource to edit..."
		_save_disabled = true

	# Support re-init
	if is_inside_tree():
		_setup_tree()

func _ready():
	# Only when launched with F6.
	if get_parent() == get_tree().root:
		# So it works as a standalone scene for easy testing.
		initialize(test_character)
		_save_disabled = true
		canceled.connect(get_tree().quit)
	_setup_tree()

func _setup_tree():
	%Title.text = _title_text
	%SaveButton.disabled = _save_disabled
	_script_tree.load_behavior(_behavior)
	_toolbox.load_skills(_skills)

func _on_save_button_pressed():
	saved.emit(_script_tree.get_behavior())

func _on_cancel_button_pressed():
	canceled.emit()
