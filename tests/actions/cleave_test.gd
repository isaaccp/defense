extends GutTest

# Level has 1 enemy.
const basic_test_level_scene = preload("res://tests/actions/basic_test_level.tscn")
const cleave_scene = preload("res://behavior/actions/scenes/cleave.tscn")
const cleave_action = preload("res://skill_tree/actions/cleave.tres")
const move_to = preload("res://skill_tree/actions/move_to.tres")
const enemy_scene = preload("res://enemies/orc_warrior/orc_warrior.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")
const enemy_target = preload("res://skill_tree/targets/enemy.tres")

var level: Level
var character: Node2D
var character_behavior: BehaviorComponent
var character_status: StatusComponent
var enemy: Node2D
var enemy_health: HealthComponent
var cleave_damage: int
var runnable_cleave_action: Action

func make_cleave_behavior() -> StoredBehavior:
	var behavior = StoredBehavior.new()
	behavior.stored_rules.append(
		TestUtils.rule_def(enemy_target, cleave_action)
	)
	behavior.stored_rules.append(
		TestUtils.rule_def(enemy_target, move_to),
	)
	return behavior

func before_all():
	runnable_cleave_action = Action.make_runnable_action(cleave_action)
	var cleave_action_scene = cleave_scene.instantiate()
	cleave_damage = Component.get_or_die(cleave_action_scene, HitboxComponent.component).hit_effect.damage
	cleave_action_scene.free()

func before_each():
	test_character.initialize("test_character", 1)
	test_character.attributes.speed = 50
	level = basic_test_level_scene.instantiate() as Level
	level.initialize([test_character])
	add_child_autoqfree(level)
	# Set up character.
	character = level.characters.get_child(0)
	character_behavior = BehaviorComponent.get_or_die(character)
	character_status = Component.get_status_component_or_die(character)
	# Set up enemy.
	enemy = level.enemies.get_child(0)
	BehaviorComponent.get_or_die(enemy).stored_behavior = StoredBehavior.new()
	enemy_health = HealthComponent.get_or_die(enemy)

func test_cleave_cooldown_reset_on_destroy():
	var extra_enemy = enemy_scene.instantiate()
	level.enemies.add_child(extra_enemy)

	TestUtils.set_character_behavior(character, make_cleave_behavior())

	# Put both enemies close to the character.
	enemy.position = character.position + Vector2.RIGHT * (runnable_cleave_action.max_distance - 15)
	extra_enemy.position = character.position + Vector2.UP * (runnable_cleave_action.max_distance - 5)

	level.start()

	# Need to wait 1 frame, otherwise health change may be reverted.
	await wait_frames(1)

	# Set health to cleave_damage - 2 to make sure cleaves kills it (orc warrior has armor 1).
	enemy_health.health = cleave_damage - 2

	await wait_for_signal(character_behavior.behavior_updated, 0.1, "Wait for cleave")
	TestUtils.assert_last_action(self, character_behavior, cleave_action.skill_name)

	# Next action should be cleave again as the cooldown should be cleared on destroying first enemy.
	await wait_for_signal(character_behavior.behavior_updated, 1.1, "Wait for next action")
	TestUtils.assert_last_action(self, character_behavior, cleave_action.skill_name)

func test_cleave_cooldown_no_reset_on_no_destroy():
	var extra_enemy = enemy_scene.instantiate()
	level.enemies.add_child(extra_enemy)

	TestUtils.set_character_behavior(character, make_cleave_behavior())

	# Put both enemies close to the character.
	enemy.position = character.position + Vector2.RIGHT * (runnable_cleave_action.max_distance - 15)
	extra_enemy.position = character.position + Vector2.UP * (runnable_cleave_action.max_distance - 5)

	level.start()

	await wait_for_signal(character_behavior.behavior_updated, 0.1, "Wait for cleave")
	TestUtils.assert_last_action(self, character_behavior, cleave_action.skill_name)

	# Next action should not be cleave as the cooldown should not be cleared.
	await wait_for_signal(character_behavior.behavior_updated, 1.1, "Wait for next action")
	TestUtils.assert_last_action_not(self, character_behavior, cleave_action.skill_name)
