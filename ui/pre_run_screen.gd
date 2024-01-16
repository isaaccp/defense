extends Screen

const skill_tree_scene = preload("res://ui/skill_tree.tscn")

var save_state: SaveState

signal continue_pressed

func _on_show(info: Dictionary):
	save_state = info.save_state

func _on_unlock_skills_button_pressed():
	var skill_tree = skill_tree_scene.instantiate() as SkillTreeUI
	skill_tree.initialize(SkillTreeUI.Mode.UNLOCK, save_state)
	skill_tree.ok_pressed.connect(_on_skill_tree_ok_pressed.bind(skill_tree))
	add_child(skill_tree)

func _on_continue_button_pressed():
	continue_pressed.emit()

func _on_skill_tree_ok_pressed(skill_tree: Node):
	skill_tree.queue_free()
