extends GutTest

# Level has 1 enemy.
const basic_test_level_scene = preload("res://tests/actions/basic_test_level.tscn")
const sword_attack_action = preload("res://skill_tree/actions/sword_attack.tres")
const charge_action = preload("res://skill_tree/actions/charge.tres")
const enemy_scene = preload("res://enemies/orc_warrior/orc_warrior.tscn")
const charge_behavior = preload("res://tests/actions/charge_behavior.tres")
const test_character = preload("res://character/playable_characters/test_character.tres")

var level: Level
var character: Node2D
var character_behavior: BehaviorComponent
var character_status: StatusComponent
var enemy: Node2D
var enemy_health: HealthComponent
var sword_damage: int
var runnable_charge_action: Action

func make_charge_behavior() -> StoredBehavior:
	return charge_behavior.duplicate()

func before_all():
	runnable_charge_action = Action.make_runnable_action(charge_action)
	var sword_attack_scene = Action.make_runnable_action(sword_attack_action).sword_attack_scene
	var sword_attack = sword_attack_scene.instantiate()
	sword_damage = Component.get_or_die(sword_attack, HitboxComponent.component).hit_effect.damage
	sword_attack.free()

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

func test_charge_short_distance():
	# Due to short distance, strength surge shouldn't trigger.
	TestUtils.set_character_behavior(character, make_charge_behavior())

	# Put the enemy close to the character, less than charge threshold distance.
	enemy.position = character.position + Vector2.RIGHT * runnable_charge_action.charge_threshold / 1.1

	level.start()

	watch_signals(character_behavior)
	watch_signals(character_status)

	# character_status.statuses_changed.connect(func(statuses): gut.p(statuses))

	await wait_for_signal(enemy_health.died, 3, "Waiting for enemy to die")
	assert_signal_emitted_with_parameters(character_status, "statuses_changed", [[&"Swiftness"]], 0)
	assert_signal_emitted_with_parameters(character_status, "statuses_changed", [[]], 1)
	assert_signal_emit_count(character_status, "statuses_changed", 2)
	# Check that first hit (second update after first heal) did 'sword_damage'.
	# (-1 because of armor, should use test enemies in tests so their attributes
	# are not changed randomly, needing adjustments).
	var health_update = get_signal_parameters(enemy_health, "health_updated", 1)[0] as HealthComponent.HealthUpdate
	assert_eq(health_update.prev_health - health_update.health, sword_damage - 1)

func test_charge_long_distance():
	# Due to distance, strength surge should trigger shortly after
	# swiftness stop.
	TestUtils.set_character_behavior(character, make_charge_behavior())

	# Put the enemy close to the character, less than charge threshold distance.
	enemy.position = character.position + Vector2.RIGHT * runnable_charge_action.charge_threshold * 1.5

	level.start()

	watch_signals(character_behavior)
	watch_signals(character_status)

	# character_status.statuses_changed.connect(func(statuses): gut.p(statuses))

	await wait_for_signal(enemy_health.died, 3, "Waiting for enemy to die")
	TestUtils.dump_all_emits(self, character_status, "statuses_changed")
	assert_signal_emitted_with_parameters(character_status, "statuses_changed", [[&"Swiftness"]], 0)
	assert_signal_emitted_with_parameters(character_status, "statuses_changed", [[]], 1)
	assert_signal_emitted_with_parameters(character_status, "statuses_changed", [[&"Strength Surge"]], 2)
	assert_signal_emit_count(character_status, "statuses_changed", 3)

	# Check that first hit (second update after first heal) did more than 'sword damage' * 2.
	# This also depends on the enemy having at least sword damage * 2 health,
	# which is the case right now but could change.
	TestUtils.dump_all_emits(self, enemy_health, "health_updated")
	var health_update = get_signal_parameters(enemy_health, "health_updated", 1)[0] as HealthComponent.HealthUpdate
	assert_eq(health_update.prev_health - health_update.health, sword_damage * 2 - 1)

func test_charge_cooldown():
	var extra_enemy = enemy_scene.instantiate()
	level.enemies.add_child(extra_enemy)

	TestUtils.set_character_behavior(character, make_charge_behavior())

	# Put the enemy close to the character, less than charge threshold distance.
	enemy.position = character.position + Vector2.RIGHT * runnable_charge_action.charge_threshold / 2.0
	# Second enemy a bit farther away.
	extra_enemy.position = enemy.position + Vector2.RIGHT * 300

	level.start()

	await wait_for_signal(character_behavior.behavior_updated, 0.1, "Wait for charge")
	TestUtils.assert_last_action(self, character_behavior, charge_action.skill_name)

	await wait_for_signal(character_behavior.behavior_updated, 2.0, "Wait for next action")
	TestUtils.assert_last_action_not(self, character_behavior, charge_action.skill_name)

	# Wait right until cooldown expires and verify we only triggered charge once.
	await wait_seconds(runnable_charge_action.cooldown - 0.1, "Waiting for cooldown to almost expire")
	assert_eq(TestUtils.count_action_triggered(self, character_behavior, charge_action.skill_name), 1)
	await wait_seconds(0.2, "Waiting for cooldown to expire")
	assert_eq(TestUtils.count_action_triggered(self, character_behavior, charge_action.skill_name), 2)
