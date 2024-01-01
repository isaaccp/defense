extends Screen

class_name UpgradeScreen

const skill_tree_scene = preload("res://ui/skill_tree.tscn")

var gameplay_characters: Array[GameplayCharacter]
var current_character: int = -1

func set_characters(characters: Array[GameplayCharacter]):
	gameplay_characters = characters

func _on_show(info: Dictionary = {}) -> void:
	current_character = -1

func on_acquired_skills_pressed(character_idx: int):
	print("acquire skills: %d" % character_idx)
	_close_existing(character_idx)
	current_character = character_idx
	var skill_tree = skill_tree_scene.instantiate()
	skill_tree.initialize(gameplay_characters[current_character])
	add_child(skill_tree)

func _close_existing(character_idx: int):
	if current_character == -1:
		return
	if current_character != character_idx:
		# TODO: If needed do "cleanup", save/discard confirmation, etc.
		for child in get_children():
			child.queue_free()
