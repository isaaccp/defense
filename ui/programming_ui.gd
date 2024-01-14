@tool
extends Control
class_name ProgrammingUI

# TODO: Make the script tree a scene, including save/cancel,
# that should make it unnecessary for us to keep behavior here.
# Then move library handling inside BehaviorLibraryUI, passing
# script tree in initialize. Library only needs script_tree to
# operate.

@export_category("Testing")
## Used for F6 debug runs.
@export var test_character: GameplayCharacter

var _title_text: String
var _behavior: StoredBehavior
var _skills: SkillTreeState
var _save_disabled: bool
var _behavior_library: BehaviorLibrary
var _behavior_library_ui: BehaviorLibraryUI
var _save_to_library_dialog: AcceptDialog

@onready var _script_tree = %Script as ScriptTree
@onready var _toolbox = %Toolbox as Toolbox

signal canceled
signal saved(behavior: StoredBehavior)

func initialize(character: GameplayCharacter, behavior_library: BehaviorLibrary = null):
	assert(is_instance_valid(character)) # TODO: Handle gracefully if needed.
	_title_text = "Configuring behavior for %s" % character.name
	_behavior = character.behavior
	_skills = character.skill_tree_state
	_save_disabled = false
	_behavior_library = behavior_library
	%BehaviorLibraryUI.initialize(_behavior_library)

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
	%BehaviorLibraryContainer.visible = _behavior_library != null
	_behavior_library_ui = %BehaviorLibraryUI
	_save_to_library_dialog = %SaveBehaviorNameDialog
	_save_to_library_dialog.register_text_enter(%BehaviorNameLineEdit)
	_setup_tree()

func _setup_tree():
	%Title.text = _title_text
	%SaveButton.disabled = _save_disabled
	_script_tree.load_behavior(_behavior)
	_toolbox.load_skills(_skills)

# TODO: Move those three inside script_tree.
func _on_save_button_pressed():
	saved.emit(_script_tree.get_behavior())

func _on_cancel_button_pressed():
	canceled.emit()

func _on_revert_button_pressed():
	_setup_tree()

# TODO: Move all below to behavior_library_ui
func _on_save_to_library_button_pressed():
	_save_to_library_dialog.show()
	var selected_behavior = _behavior_library_ui.get_selected()
	%BehaviorNameLineEdit.text = selected_behavior.name if selected_behavior else ""

func _on_save_behavior_name_dialog_confirmed():
	var behavior_name = %BehaviorNameLineEdit.text
	var behavior = _script_tree.get_behavior()
	behavior.name = behavior_name
	assert(not behavior_name.is_empty())
	if _behavior_library.contains(behavior_name):
		_behavior_library.replace(behavior)
	else:
		_behavior_library.add(behavior)
	_behavior_library_ui.refresh()

func _on_behavior_name_line_edit_text_changed(new_text: String):
	_save_to_library_dialog.get_ok_button().disabled = new_text.is_empty()

func _on_behavior_library_ui_behavior_activated(behavior):
	_script_tree.load_behavior(behavior)
