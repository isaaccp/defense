@tool
extends Control
class_name ProgrammingUI

@export_category("Testing")
## Used for F6 debug runs.
@export var test_character: GameplayCharacter

signal canceled
signal saved(behavior: StoredBehavior)

func initialize(title: String, behavior: StoredBehavior, acquired_skills: SkillTreeState, behavior_library: BehaviorLibrary = null, is_editor = false):
	assert(behavior)
	assert(acquired_skills)
	%Title.text = title
	%BehaviorLibraryUI.initialize(behavior_library, %BehaviorEditor as BehaviorEditor)
	%BehaviorLibraryContainer.visible = behavior_library != null
	%BehaviorEditor.initialize(behavior, is_editor)
	%Toolbox.initialize(acquired_skills)

func editor_initialize(b: StoredBehavior):
	if not b:
		print("unexpected null StoredBehavior in editor_initialized")
		return

	var acquired_skills = SkillTreeState.new()
	acquired_skills.full = true

	initialize("Editing %s" % b.resource_path, b, acquired_skills, null, true)

func _ready():
	# Only when launched with F6.
	if get_parent() == get_tree().root:
		# So it works as a standalone scene for easy testing.
		_initialize_from_test_character()
		canceled.connect(get_tree().quit)

func _initialize_from_test_character():
	initialize(test_character.name, test_character.behavior, test_character.acquired_skills, BehaviorLibrary.new())

func _on_behavior_editor_behavior_saved(behavior):
	saved.emit(behavior)

func _on_behavior_editor_canceled():
	canceled.emit()
