extends Screen

class_name UpgradeScreen

var gameplay_characters: Array[GameplayCharacter]

func set_characters(characters: Array[GameplayCharacter]):
	gameplay_characters = characters

func on_acquired_skills_pressed(character_idx: int):
	print("acquire skills: %d" % character_idx)

func _on_show(info: Dictionary = {}) -> void:
	pass
