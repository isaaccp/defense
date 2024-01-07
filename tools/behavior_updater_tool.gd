@tool
extends EditorScript

var skip = [".godot", ".git", "addons", "assets", "webrtc"]
var finished = false

func _run():
	_process_tree()

func _process_tree():
	await _process_directory("res://")

func _process_directory(dir_path: String):
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not file_name in skip:
				var full_path: String
				if dir_path == "res://":
					full_path = "res://%s" % file_name
				else:
					full_path = "%s/%s" % [dir_path, file_name]
				if dir.current_is_dir():
					_process_directory(full_path)
				else:
					_process_file(full_path)
			file_name = dir.get_next()

func _process_file(file_name: String):
	if file_name.ends_with(".tscn"):
		_process_scene_file(file_name)
	elif file_name.ends_with(".tres"):
		_process_resource_file(file_name)

func _grep_behavior_gd(file_name) -> bool:
	var file = FileAccess.open(file_name, FileAccess.READ)
	var content = file.get_as_text()
	if content.contains("behavior.gd"):
		return true
	return false

func _process_scene_file(file_name: String):
	if not _grep_behavior_gd(file_name):
		return
	print("%s contains a behavior" % file_name)

func _process_resource_file(file_name: String):
	if not _grep_behavior_gd(file_name):
		return
	print("%s contains a behavior" % file_name)
