extends Screen

const skill_tree_scene = preload("res://ui/skill_tree.tscn")

func _on_show(info: Dictionary):
	var persistent_state = Component.get_persistent_game_state_component_or_die(info.character)
	var skill_tree = skill_tree_scene.instantiate() as SkillTreeUI
	skill_tree.initialize(SkillTreeUI.Mode.ACQUIRE, info.save_state, persistent_state.state, false)
	skill_tree.ok_pressed.connect(_on_skill_tree_ok_pressed.bind(skill_tree))
	add_child(skill_tree)

func _on_skill_tree_ok_pressed(skill_tree: Control):
	skill_tree.queue_free()
	ui_layer.hide_screen()
	ui_layer.hud.show()
