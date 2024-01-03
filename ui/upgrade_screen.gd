extends Screen

class_name UpgradeScreen

const skill_tree_scene = preload("res://ui/skill_tree.tscn")

var gameplay_characters: Array[GameplayCharacter]
var force_acquire_all: bool

func setup(characters: Array[GameplayCharacter], force_acquire_all_upgrades: bool):
	gameplay_characters = characters
	force_acquire_all = force_acquire_all_upgrades

func _on_show(info: Dictionary = {}) -> void:
	pass

func on_acquired_skills_pressed(character_idx: int):
	var skill_tree = skill_tree_scene.instantiate()
	skill_tree.initialize(gameplay_characters[character_idx], force_acquire_all)
	skill_tree.ok_pressed.connect(_clear)
	ui_layer.hud.hide()
	add_child(skill_tree)

func _clear():
	ui_layer.hud.show()
	for child in get_children():
		child.queue_free()
