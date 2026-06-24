extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Usage: godot --headless -s tools/convert_enemy.gd -- <scene_path> <output_tres_path>")
		quit(1)
		return
	
	var scene_path: String = args[0]
	var output_path: String = args[1]
	
	var scene := load(scene_path)
	if not scene:
		push_error("Failed to load scene: %s" % scene_path)
		quit(1)
		return
		
	var inst := scene.instantiate() as Node
	if not inst:
		push_error("Failed to instantiate scene: %s" % scene_path)
		quit(1)
		return
		
	var enemy_config := EnemyConfig.new()
	enemy_config.name = inst.get("actor_name")
	
	# Extract collision shape from root
	var col_shape_node := inst.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col_shape_node and col_shape_node.shape:
		enemy_config.collision_shape = col_shape_node.shape.duplicate()
		
	# Extract attributes config
	var attr_comp := inst.get_node_or_null("AttributesComponent") as AttributesComponent
	if attr_comp and attr_comp.base_attributes:
		var attr_cfg := AttributesComponentConfig.new()
		attr_cfg.attributes = attr_comp.base_attributes.duplicate()
		enemy_config.attributes_component_config = attr_cfg
		
	# Extract behavior config
	var behav_comp := inst.get_node_or_null("BehaviorComponent") as BehaviorComponent
	if behav_comp and behav_comp.stored_behavior:
		var behav_cfg := BehaviorComponentConfig.new()
		behav_cfg.stored_behavior = behav_comp.stored_behavior.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
		enemy_config.behavior_component_config = behav_cfg
		
	# Extract hurtbox config
	var hurt_comp := inst.get_node_or_null("HurtboxComponent")
	if hurt_comp:
		var hurt_col_shape_node := hurt_comp.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if hurt_col_shape_node and hurt_col_shape_node.shape:
			var hurt_cfg := HurtboxComponentConfig.new()
			hurt_cfg.collision_shape = hurt_col_shape_node.shape.duplicate()
			enemy_config.hurtbox_component_config = hurt_cfg
			
	# Extract animation library from AnimationComponent's AnimationPlayer
	var anim_comp := inst.get_node_or_null("AnimationComponent")
	if anim_comp:
		var anim_player := anim_comp.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if anim_player:
			var anim_cfg := AnimationComponentConfig.new()
			var anim_lib := AnimationLibrary.new()
			var lib_names := anim_player.get_animation_library_list()
			for lib_name in lib_names:
				var lib := anim_player.get_animation_library(lib_name)
				var anim_list := lib.get_animation_list()
				for anim_name in anim_list:
					var anim := lib.get_animation(anim_name).duplicate() as Animation
					# Rewrite track paths from "../Sprite2D:texture" to ".:texture"
					for track_idx in range(anim.get_track_count()):
						var track_path := anim.track_get_path(track_idx)
						var track_path_str := str(track_path)
						if track_path_str.begins_with("../Sprite2D:"):
							var suffix := track_path_str.substr("../Sprite2D:".length())
							anim.track_set_path(track_idx, NodePath(".:" + suffix))
					anim_lib.add_animation(anim_name, anim)
			anim_cfg.animation_library = anim_lib
			enemy_config.animation_component_config = anim_cfg
			
	var err := ResourceSaver.save(enemy_config, output_path)
	if err != OK:
		push_error("Failed to save to: %s error: %s" % [output_path, err])
		quit(1)
	else:
		print("Successfully saved config to: %s" % output_path)
		quit(0)
