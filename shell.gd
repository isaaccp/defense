@tool

extends EditorScript

func _run():
	var strings = ["a", "b", "", "c"]
	print(Utils.filter_and_join_strings(strings))
