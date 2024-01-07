@tool

extends EditorScript

func _run():
	var s = load("res://skill_tree/targets/self.tres")
	print(s.sortable)
