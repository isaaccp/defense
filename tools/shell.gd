@tool

extends EditorScript

func _run():
	var format_string = "{str} {str}"
	var actual_string = format_string.format({"str": "Godot"})
	print(actual_string)

	const projectile_ward = preload("res://behavior/actions/scenes/projectile_ward.tscn")
	print(projectile_ward._bundled)

	print("FooBar".capitalize())
