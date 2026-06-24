@tool
extends Node2D

const enemy_scene = preload("res://enemies/enemy.tscn")

@export var config: EnemyConfig:
	set(value):
		config = value
		if Engine.is_editor_hint() and is_inside_tree():
			_update_enemy()

@export var save_config: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			if config:
				if config.resource_path.is_empty():
					push_error("This config resource does not have a file path yet (it was created in memory). Please use 'save_as_path' and 'save_as_new_config' to save it first.")
				else:
					_save_to_resource(config.resource_path)
			else:
				push_error("No config loaded to save!")
			save_config = false

@export_file("*.tres") var save_as_path: String

@export var save_as_new_config: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			if save_as_path.is_empty():
				push_error("Cannot save: save_as_path is empty!")
			else:
				_save_to_resource(save_as_path)
			save_as_new_config = false

var enemy: Enemy

func _ready():
	if not Engine.is_editor_hint():
		# At runtime (play mode), clear editor previews completely
		for child in get_children():
			child.queue_free()
		return
	
	_create_editor_guide()
	
	# In the editor, ensure the visual preview is updated if we have a config saved in the scene
	if config:
		_update_enemy()

func _create_editor_guide():
	var existing = get_node_or_null("EditorGuideCanvas")
	if existing:
		existing.queue_free()
		
	var canvas = CanvasLayer.new()
	canvas.name = "EditorGuideCanvas"
	add_child(canvas)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 260)
	panel.position = Vector2(20, 20)
	
	# Modern dark semi-transparent theme
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.12, 0.12, 0.12, 0.85)
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.border_color = Color(0.3, 0.3, 0.3, 0.8)
	panel.add_theme_stylebox_override("panel", stylebox)
	
	canvas.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "🛠️ Enemy Config Editor Guide"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(title)
	
	var hs = HSeparator.new()
	vbox.add_child(hs)
	
	var desc = Label.new()
	desc.text = "Only the following components are saved back to the EnemyConfig (.tres) file:\n\n" \
		+ "• Collision Shapes: Modify shapes on root 'CollisionShape2D' or 'HurtboxComponent/CollisionShape2D'\n" \
		+ "• Attributes: Edit 'base_attributes' on 'AttributesComponent'\n" \
		+ "• Behavior: Edit 'stored_behavior' on 'BehaviorComponent'\n" \
		+ "• Animations: Edit 'animation_library' on 'AnimationPlayer'\n" \
		+ "• General: Edit 'actor_name' on root 'Enemy' node\n\n" \
		+ "Use the Inspector on the 'EnemyEditor' root node to load a config, save changes, or save as a new config."
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

func _update_enemy():
	# Clean up any existing preview child
	for child in get_children():
		if child is Enemy:
			child.queue_free()
	
	enemy = null
	
	if not config:
		return
		
	# Ensure the sub-resources exist so the user can edit them in the inspector
	if not config.attributes_component_config:
		config.attributes_component_config = AttributesComponentConfig.new()
	if not config.attributes_component_config.attributes:
		config.attributes_component_config.attributes = Attributes.new()
		
	if not config.behavior_component_config:
		config.behavior_component_config = BehaviorComponentConfig.new()
	if not config.behavior_component_config.stored_behavior:
		config.behavior_component_config.stored_behavior = StoredBehavior.new()
		
	if not config.hurtbox_component_config:
		config.hurtbox_component_config = HurtboxComponentConfig.new()
		
	if not config.animation_component_config:
		config.animation_component_config = AnimationComponentConfig.new()
	if not config.animation_component_config.animation_library:
		config.animation_component_config.animation_library = AnimationLibrary.new()

	enemy = enemy_scene.instantiate() as Enemy
	enemy.name = "Enemy"
	
	# Apply basic properties
	enemy.actor_name = config.name
	
	# Pass config to the enemy
	enemy.config = config
	
	# Add child first so ready/children setup happens
	add_child(enemy)
	
	# Set owners so they are editable in editor docks
	enemy.owner = self
	set_editable_instance(enemy, true)
	
	# Apply collision shapes (since ready might have run with empty shape or not run yet)
	var col_shape_2d = enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col_shape_2d:
		col_shape_2d.shape = config.collision_shape
		
	var hurtbox_col_shape = enemy.get_node_or_null("HurtboxComponent/CollisionShape2D") as CollisionShape2D
	if hurtbox_col_shape:
		hurtbox_col_shape.shape = config.hurtbox_component_config.collision_shape
		
	# Apply base attributes to AttributesComponent
	var attr_component = enemy.get_node_or_null("AttributesComponent") as AttributesComponent
	if attr_component:
		attr_component.base_attributes = config.attributes_component_config.attributes
		
	# Apply stored behavior to BehaviorComponent
	var behavior_component = enemy.get_node_or_null("BehaviorComponent") as BehaviorComponent
	if behavior_component:
		behavior_component.stored_behavior = config.behavior_component_config.stored_behavior
		
	# Configure AnimationPlayer library
	var anim_player = enemy.get_node_or_null("AnimationComponent/AnimationPlayer") as AnimationPlayer
	if anim_player:
		if anim_player.has_animation_library(""):
			anim_player.remove_animation_library("")
		anim_player.add_animation_library("", config.animation_component_config.animation_library)
		
		# Play idle animation if present
		if anim_player.has_animation("idle"):
			anim_player.play("idle")

func _save_to_resource(path: String):
	if not config:
		push_error("No config loaded to save!")
		return
	if not enemy:
		push_error("No instantiated enemy preview to save!")
		return
		
	print("Saving enemy config to: ", path)
	
	# Copy simple fields
	config.name = enemy.actor_name
	
	# Copy root collision shape
	var col_shape_2d = enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col_shape_2d:
		config.collision_shape = col_shape_2d.shape
		
	# Copy hurtbox collision shape
	var hurtbox_col_shape = enemy.get_node_or_null("HurtboxComponent/CollisionShape2D") as CollisionShape2D
	if hurtbox_col_shape:
		if not config.hurtbox_component_config:
			config.hurtbox_component_config = HurtboxComponentConfig.new()
		config.hurtbox_component_config.collision_shape = hurtbox_col_shape.shape
		
	# Copy base attributes from AttributesComponent
	var attr_component = enemy.get_node_or_null("AttributesComponent") as AttributesComponent
	if attr_component:
		if not config.attributes_component_config:
			config.attributes_component_config = AttributesComponentConfig.new()
		config.attributes_component_config.attributes = attr_component.base_attributes
		
	# Copy stored behavior from BehaviorComponent
	var behavior_component = enemy.get_node_or_null("BehaviorComponent") as BehaviorComponent
	if behavior_component:
		if not config.behavior_component_config:
			config.behavior_component_config = BehaviorComponentConfig.new()
		config.behavior_component_config.stored_behavior = behavior_component.stored_behavior
		
	# Copy animation library from AnimationPlayer
	var anim_player = enemy.get_node_or_null("AnimationComponent/AnimationPlayer") as AnimationPlayer
	if anim_player:
		var anim_library = anim_player.get_animation_library("")
		if not config.animation_component_config:
			config.animation_component_config = AnimationComponentConfig.new()
		config.animation_component_config.animation_library = anim_library

	var err = ResourceSaver.save(config, path)
	if err == OK:
		print("Successfully saved enemy config to: ", path)
		config.take_over_path(path)
	else:
		push_error("Failed to save enemy config to: ", path, ". Error: ", err)
