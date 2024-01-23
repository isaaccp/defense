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
	%BehaviorLibraryUI.initialize(behavior_library, acquired_skills, %BehaviorEditor as BehaviorEditor)
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


func library_editor_initialize(l: BehaviorLibrary):
	if not l:
		print("unexpected null BehaviorLibrary in library_editor_initialize")
		return

	var acquired_skills = SkillTreeState.new()
	acquired_skills.full = true

	initialize("Editing %s" % l.resource_path, StoredBehavior.new(), acquired_skills, l, true)

func _ready():
	# Only when launched with F6.
	if get_parent() == get_tree().root:
		_standalone_ready.call_deferred()

func _on_behavior_editor_behavior_saved(behavior):
	saved.emit(behavior)

func _on_behavior_editor_canceled():
	canceled.emit()

func _standalone_ready():
	# Immediately remove self, we'll test with a copy. Keep parent ref.
	var parent = get_parent()
	get_parent().remove_child(self)
	_standalone_ready_next_frame.call_deferred(parent)

func _standalone_ready_next_frame(parent: Node):
	# Just so we don't trigger again the _ready() F6 detector.
	var node = Node.new()
	parent.add_child(node)
	var programming_ui = load(scene_file_path).instantiate()
	programming_ui._initialize_from_test_character()
	programming_ui.canceled.connect(parent.get_tree().quit)
	node.add_child(programming_ui)

func _initialize_from_test_character():
	initialize(test_character.name, test_character.behavior, test_character.acquired_skills, BehaviorLibrary.new())
