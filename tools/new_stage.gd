extends SceneTree

# Scaffolds a new stage scene inheriting base_level.tscn. Usage:
#   godot --headless -s tools/new_stage.gd -- <stage_name>
#
# Writes res://levels/stages/<stage_name>.tscn with the inheritance header
# set up correctly and StartingPositions placed at reasonable defaults. You
# add decoration / towers / placement zones from the editor or in text.

const BASE_PATH := "res://levels/base_level.tscn"
const OUTPUT_DIR := "res://levels/stages"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("Usage: godot --headless -s tools/new_stage.gd -- <stage_name>")
		quit(1)
		return
	var stage_name: String = args[0]
	var output_path := "%s/%s.tscn" % [OUTPUT_DIR, stage_name]

	if FileAccess.file_exists(output_path):
		push_error("File already exists: %s" % output_path)
		quit(1)
		return

	var base_uid_id := ResourceLoader.get_resource_uid(BASE_PATH)
	if base_uid_id == ResourceUID.INVALID_ID:
		push_error("Could not get UID for %s — does it exist?" % BASE_PATH)
		quit(1)
		return
	var base_uid := ResourceUID.id_to_text(base_uid_id)
	var new_uid_id := ResourceUID.create_id()
	var new_uid := ResourceUID.id_to_text(new_uid_id)

	var content := """[gd_scene load_steps=2 format=3 uid="%s"]

[ext_resource type="PackedScene" uid="%s" path="%s" id="1_base"]

[node name="Level" instance=ExtResource("1_base")]

[node name="First" parent="StartingPositions" index="0"]
position = Vector2(331, 179)

[node name="Second" parent="StartingPositions" index="1"]
position = Vector2(331, 339)
""" % [new_uid, base_uid, BASE_PATH]

	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		push_error("Could not write: %s (error %s)" % [output_path, FileAccess.get_open_error()])
		quit(1)
		return
	file.store_string(content)
	file.close()
	# Register the UID so subsequent tool invocations (e.g. new_level.gd
	# pointing at this stage) can resolve it without a project rescan.
	ResourceUID.add_id(new_uid_id, output_path)
	print("Created %s" % output_path)
	print("Next: open in editor (or text) to add towers, decoration scatters, placement zones.")
	quit(0)
