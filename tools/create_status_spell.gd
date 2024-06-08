@tool
extends EditorScript

var base_name = "magic_armor"

const base_action_scene = preload("res://behavior/actions/scenes/base_single_target_action_scene.tscn")

var statuses_path = "res://effects/statuses"
var actions_path = "res://skill_tree/actions"
var action_scripts_path = "res://behavior/actions"
var action_scenes_path = "res://behavior/actions/scenes"

func _show_error(error: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Error in  create_status_spell tool"
	dialog.dialog_text = error
	EditorInterface.popup_dialog_centered(dialog)

func _run():
	if base_name == "unset":
		_show_error("Please set 'base_name'")
		return
	create_status_spell()

func create_status_script() -> String:
	const status_script_content = """extends Effect

# func on_effect_added():
#	pass
#
# func modify_attributes(base_attributes: Attributes) -> void:
#   pass
#
# func on_effect_removed():
#   pass
"""
	var status_script_path = statuses_path + "/" + base_name + ".gd"
	var status_script = FileAccess.open(status_script_path, FileAccess.WRITE)
	status_script.store_string(status_script_content)
	print("created status script: %s" % status_script_path)
	return status_script_path

func create_status_resource(status_script_path: String) -> String:
	var status_resource_path = statuses_path + "/" + base_name + ".tres"
	var status_def = StatusDef.new()
	status_def.description = "TBD: description"
	status_def.name = base_name.capitalize()
	status_def.effect_script = load(status_script_path)
	ResourceSaver.save(status_def, status_resource_path)
	print("created status resource: %s" % status_resource_path)
	return status_resource_path

# Hack to create inherited scene from:
# https://github.com/godotengine/godot-proposals/issues/3907#issuecomment-1297031018
# Can remove when/if the proposal is resolved (there is a pending PR for it).
func create_inherited_scene(_inherits: PackedScene, _root_name: String = "") -> PackedScene:
	if(_root_name == ""):
		_root_name = _inherits._bundled["names"][0];
	var scene := PackedScene.new();
	scene._bundled = {
		"base_scene": 0, "conn_count": 0, "conns": [], "editable_instances": [],
		"names": [_root_name], "node_count": 1, "node_paths": [],
		"nodes": [-1, -1, 2147483647, 0, -1, 0, 0],
		"variants": [_inherits], "version": 3,
	}
	return scene

func create_action_scene(status_resource_path: String):
	var action_scene_path = action_scenes_path + "/" + base_name + ".tscn"
	var scene = create_inherited_scene(base_action_scene, base_name.to_pascal_case())
	# This makes the scene no longer maintain inheritance.
	# Comment out for the time being.
	#var instance = scene.instantiate() as ActionScene
	#var hitbox_component = instance.get_component_or_die(HitboxComponent) as HitboxComponent
	#hitbox_component.hit_effect = HitEffect.new()
	#hitbox_component.hit_effect.status = load(status_resource_path)
	#var animation_component = instance.get_component_or_die(AnimationComponent)
	#var animation_player = AnimationPlayer.new()
	#animation_component.add_child(animation_player)
	#scene.pack(instance)
	print("created action scene: %s" % action_scene_path)
	ResourceSaver.save(scene, action_scene_path)

func create_action_script() -> String:
	const action_script_template = """extends SpawnAtTargetNodePositionAction

const {base_name}_scene = preload("res://behavior/actions/scenes/{base_name}.tscn")

func _init():
	spawn_scene = {base_name}_scene
	prepare_time = 0.25
	duration = 0.5
	cooldown = 5.0
	max_distance = 200

func description():
	return "TBD: description"
"""
	var content = action_script_template.format({"base_name": base_name})
	var action_script_path = action_scripts_path + "/" + base_name + "_action.gd"
	var action_script = FileAccess.open(action_script_path, FileAccess.WRITE)
	action_script.store_string(content)
	print("created action script: %s" % action_script_path)
	return action_script_path

func create_action_resource(action_script_path: String):
	var action_resource_path = actions_path + "/" + base_name + ".tres"
	var action_def = ActionDef.new()
	action_def.skill_name = base_name.capitalize()
	action_def.action_script = load(action_script_path)
	print("created action resource: %s" % action_resource_path)
	ResourceSaver.save(action_def, action_resource_path)

func create_status_spell():
	var status_script_path = create_status_script()
	var status_resource_path = create_status_resource(status_script_path)
	create_action_scene(status_resource_path)
	var action_script_path = create_action_script()
	create_action_resource(action_script_path)
	print("edit created resources as needed")
