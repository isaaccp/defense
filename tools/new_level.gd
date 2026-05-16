extends SceneTree

# Scaffolds a new level scene inheriting a stage scene. Usage:
#   godot --headless -s tools/new_level.gd -- <stage_path> <level_name> [output_subdir]
#
# Example:
#   godot --headless -s tools/new_level.gd -- \
#     res://levels/stages/forest_stage_right_side_open.tscn one_test_spawner
#
# Default output path: res://levels/main/<stage_basename>/<level_name>.tscn
# Override the subdir under levels/main/ by passing a third argument.
# Reminder: new levels must be added to levels/main/main_levels.tres to
# appear in runs.

const OUTPUT_ROOT := "res://levels/main"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("Usage: godot --headless -s tools/new_level.gd -- <stage_path> <level_name> [output_subdir]")
		quit(1)
		return
	var stage_path: String = args[0]
	if not stage_path.begins_with("res://"):
		stage_path = "res://" + stage_path
	var level_name: String = args[1]
	var subdir: String = args[2] if args.size() > 2 else stage_path.get_file().get_basename()
	var output_dir := "%s/%s" % [OUTPUT_ROOT, subdir]
	var output_path := "%s/%s.tscn" % [output_dir, level_name]

	if FileAccess.file_exists(output_path):
		push_error("File already exists: %s" % output_path)
		quit(1)
		return

	var stage_uid := _read_uid_from_tscn(stage_path)
	if stage_uid.is_empty():
		push_error("Could not read UID from %s — does it exist?" % stage_path)
		quit(1)
		return
	var new_uid_id := ResourceUID.create_id()
	var new_uid := ResourceUID.id_to_text(new_uid_id)

	# Ensure output dir exists.
	var dir_err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		push_error("Could not create dir %s (error %s)" % [output_dir, dir_err])
		quit(1)
		return

	var content := """[gd_scene load_steps=2 format=3 uid="%s"]

[ext_resource type="PackedScene" uid="%s" path="%s" id="1_stage"]

[node name="Level" instance=ExtResource("1_stage")]
""" % [new_uid, stage_uid, stage_path]

	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		push_error("Could not write: %s (error %s)" % [output_path, FileAccess.get_open_error()])
		quit(1)
		return
	file.store_string(content)
	file.close()
	ResourceUID.add_id(new_uid_id, output_path)
	print("Created %s" % output_path)
	print("Next: add spawners as children of YSorted/Spawners.")
	print("Then register the level in levels/main/main_levels.tres so it appears in runs.")
	quit(0)

# Extracts the uid="uid://..." value from the first line of a .tscn / .tres
# file. Works across separate Godot processes (unlike ResourceLoader's UID
# lookup, which only sees IDs registered in the current process).
func _read_uid_from_tscn(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return ""
	var first_line := f.get_line()
	f.close()
	var regex := RegEx.new()
	regex.compile('uid="(uid://[^"]+)"')
	var m := regex.search(first_line)
	return m.get_string(1) if m else ""
