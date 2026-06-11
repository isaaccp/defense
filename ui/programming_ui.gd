@tool
extends Control
class_name ProgrammingUI

@export_category("Testing")
## Used for F6 debug runs.
@export var test_character: GameplayCharacter
@export var test_behavior_library: BehaviorLibrary

signal canceled
signal saved(behavior: StoredBehavior)

func initialize(title: String, behavior: StoredBehavior, acquired_skills: SkillTreeState, behavior_library: BehaviorLibrary = null, is_editor = false):
	assert(behavior)
	assert(acquired_skills)
	%Title.text = title
	%BehaviorLibraryUI.initialize(behavior_library, acquired_skills, %BehaviorEditor as BehaviorEditor)
	%BehaviorLibraryContainer.visible = behavior_library != null
	%BehaviorEditor.initialize(behavior, acquired_skills, is_editor)
	%ToolboxFilter.clear()
	%Toolbox.initialize(acquired_skills)
	if not %Toolbox.drag_started.is_connected(_on_toolbox_drag_started):
		%Toolbox.drag_started.connect(_on_toolbox_drag_started)

func _on_toolbox_drag_started(drag_type: BehaviorEditorTypes.SlotType) -> void:
	(%BehaviorEditor as BehaviorEditor).highlight_drop_targets(drag_type)

func _on_toolbox_filter_text_changed(text: String) -> void:
	%Toolbox.set_filter(text)

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
	node.add_child(programming_ui)
	programming_ui._initialize_from_test_character()
	programming_ui.canceled.connect(parent.get_tree().quit)

func _initialize_from_test_character():
	var populate = false
	for arg in OS.get_cmdline_args():
		if arg == "--populate_behavior":
			populate = true
			break
	if populate:
		_populate_test_behavior(test_character.behavior)
	initialize(test_character.name, test_character.behavior, test_character.acquired_skills, test_behavior_library)

func _populate_test_behavior(behavior: StoredBehavior):
	behavior.stored_rules.clear()
	
	# Rule 1: Target "Enemy" -> Action "Move To"
	var t1 = StoredParamSkill.from_skill(SkillManager.make_target_selection_instance(&"Enemy"))
	var a1 = StoredParamSkill.from_skill(SkillManager.make_action_instance(&"Move To"))
	behavior.stored_rules.append(RuleDef.make(t1, a1))

	# Rule 2: Target "Enemy" -> Action "Sword Attack"
	var t2 = StoredParamSkill.from_skill(SkillManager.make_target_selection_instance(&"Enemy"))
	var a2 = StoredParamSkill.from_skill(SkillManager.make_action_instance(&"Sword Attack"))
	behavior.stored_rules.append(RuleDef.make(t2, a2))

	# Rule 3: Target "Enemy" -> Action "Bow Attack" -> Condition "Once"
	var t3 = StoredParamSkill.from_skill(SkillManager.make_target_selection_instance(&"Enemy"))
	var a3 = StoredParamSkill.from_skill(SkillManager.make_action_instance(&"Bow Attack"))
	var c3 = StoredParamSkill.from_skill(SkillManager.make_condition_instance(&"Once"))
	behavior.stored_rules.append(RuleDef.make(t3, a3, c3))
