extends Node2D

@export var level_scene = preload("res://levels/test/action_player_test_level.tscn")
@export var action_scene: PackedScene
@export var spawn_interval = 2.0

var gameplay: Gameplay

# TODO: Add a panel that shows the scenes exported variables, so you can
# easily change them around and see the effect without having to reload.
# TODO: Make it so things look the same size as in the real game (as of now
# they don't because of the viewport, maybe just load gameplay.tscn and a
# dummy level).
func _ready():
	gameplay = %Gameplay
	_start_spawning.call_deferred()

func _start_spawning():
	var level = level_scene.instantiate()

	var level_provider = LevelProvider.new()
	level_provider.levels.append(level_scene)

	level.prepare_test_gameplay_characters()

	gameplay.characters = level.test_gameplay_characters
	gameplay.level_provider = level_provider
	gameplay.ui_layer.show()
	gameplay.ui_layer.hud.show()
	gameplay.play_next_level()
	gameplay._on_all_ready()

	while true:
		var instance = action_scene.instantiate() as ActionScene
		instance.initialize("test_owner", ActionDef.new(), %AttributesComponent, %SideComponent, null)
		# TODO: Allow to configure some details like initial direction, etc
		# when the action scene player is used through an action scene's F6.
		# This is ~hard because right now initial positioning, etc is done in the
		# action that spawns the projectile, maybe it should be moved to the
		# action scene itself.
		if _setup_action_scene(instance):
			gameplay.level.add_child(instance)
			instance.run()
			instance.global_position = Global.subviewport.get_visible_rect().size / 2.0
		await get_tree().create_timer(spawn_interval).timeout

func _get_enemy() -> Actor:
	if gameplay.level.enemies.get_child_count() > 0:
		return gameplay.level.enemies.get_child(0)
	return null

# Setup action scene for run. Return false if setup can't be done
# and action won't be run.
func _setup_action_scene(instance: ActionScene) -> bool:
	var enemy = _get_enemy()
	var motion = ProjectileMotionComponent.get_or_null(instance)
	if motion and motion.homing:
		if enemy == null:
			return false
		motion.target = Target.make_actor_target(enemy, null)
	var hitbox = HitboxComponent.get_or_null(instance)
	if hitbox and hitbox.hit_only_target:
		if enemy == null:
			return false
		hitbox.target = enemy
	return true
