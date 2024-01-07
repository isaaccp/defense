extends GutTest

# Level has 1 enemy.
const basic_test_level_scene = preload("res://tests/actions/basic_test_level.tscn")
const sword_attack_scene = SwordAttackAction.sword_attack_scene
const enemy_scene = preload("res://enemies/orc_warrior/orc_warrior.tscn")

const test_character = preload("res://character/playable_characters/test_character.tres")

var level: Level
var character: Node2D
var character_behavior: BehaviorComponent
var character_status: StatusComponent
var enemy: Node2D
var enemy_health: HealthComponent
var sword_damage: int

func make_charge_behavior() -> Behavior:
	var behavior = Behavior.new()
	behavior.rules.append(
		Rule.make(
			SkillManager.make_target_selection_instance(TargetSelectionDef.Id.ENEMY),
			SkillManager.make_action_instance(ActionDef.Id.SWORD_ATTACK),
		)
	)
	behavior.rules.append(
		Rule.make(
			SkillManager.make_target_selection_instance(TargetSelectionDef.Id.ENEMY),
			SkillManager.make_action_instance(ActionDef.Id.CHARGE),
		)
	)
	return behavior

func before_all():
	var sword_attack = sword_attack_scene.instantiate()
	sword_damage = Component.get_or_die(sword_attack, HitboxComponent.component).hit_effect.damage
	sword_attack.free()

func before_each():
	level = basic_test_level_scene.instantiate() as Level
	level.initialize([test_character])
	add_child_autoqfree(level)
	# Set up character.
	character = level.characters.get_child(0)
	character_behavior = Component.get_behavior_component_or_die(character)
	character_status = Component.get_status_component_or_die(character)
	# Set up enemy.
	enemy = level.enemies.get_child(0)
	Component.get_behavior_component_or_die(enemy).behavior = Behavior.new()
	enemy_health = Component.get_health_component_or_die(enemy)

func test_charge_short_distance():
	# Due to short distance, strength surge shouldn't trigger.
	TestUtils.set_character_behavior(character, make_charge_behavior())

	# Put the enemy close to the character, less than charge threshold distance.
	enemy.position = character.position + Vector2.RIGHT * ChargeAction.charge_threshold / 2.0

	level.start()

	watch_signals(character_behavior)
	watch_signals(character_status)

	# character_status.statuses_changed.connect(func(statuses): gut.p(statuses))

	await wait_for_signal(enemy_health.died, 3, "Waiting for enemy to die")
	assert_signal_emitted_with_parameters(character_status, "statuses_changed", [[StatusDef.Id.SWIFTNESS]], 0)
	assert_signal_emitted_with_parameters(character_status, "statuses_changed", [[]], 1)
	assert_signal_emit_count(character_status, "statuses_changed", 2)
	# Check that first hit (second update after first heal) did 'sword_damage'.
	var health_update = get_signal_parameters(enemy_health, "health_updated", 1)[0] as HealthComponent.HealthUpdate
	assert_eq(health_update.prev_health - health_update.health, sword_damage)

func test_charge_long_distance():
	# Due to distance, strength surge should trigger shortly after
	# swiftness stop.
	TestUtils.set_character_behavior(character, make_charge_behavior())

	# Put the enemy close to the character, less than charge threshold distance.
	enemy.position = character.position + Vector2.RIGHT * ChargeAction.charge_threshold * 1.5

	level.start()

	watch_signals(character_behavior)
	watch_signals(character_status)

	# character_status.statuses_changed.connect(func(statuses): gut.p(statuses))

	await wait_for_signal(enemy_health.died, 3, "Waiting for enemy to die")
	assert_signal_emitted_with_parameters(character_status, "statuses_changed", [[StatusDef.Id.SWIFTNESS]], 0)
	assert_signal_emitted_with_parameters(character_status, "statuses_changed", [[]], 1)
	assert_signal_emitted_with_parameters(character_status, "statuses_changed", [[StatusDef.Id.STRENGTH_SURGE]], 2)
	assert_signal_emit_count(character_status, "statuses_changed", 3)

	# Check that first hit (second update after first heal) did more than 'sword damage' * 2.
	# The '2' is hardcoded in StatusComponent as of now.
	# This also depends on the enemy having at least sword damage * 2 health,
	# which is the case right now but could change.
	var health_update = get_signal_parameters(enemy_health, "health_updated", 1)[0] as HealthComponent.HealthUpdate
	assert_eq(health_update.prev_health - health_update.health, sword_damage * 2)

func test_charge_cooldown():
	var extra_enemy = enemy_scene.instantiate()
	level.enemies.add_child(extra_enemy)

	TestUtils.set_character_behavior(character, make_charge_behavior())

	# Put the enemy close to the character, less than charge threshold distance.
	enemy.position = character.position + Vector2.RIGHT * ChargeAction.charge_threshold / 2.0
	# Second enemy a bit farther away.
	extra_enemy.position = enemy.position + Vector2.RIGHT * 300

	level.start()

	await wait_for_signal(character_behavior.behavior_updated, 0.1, "Wait for charge")
	TestUtils.assert_last_action(self, character_behavior, ActionDef.Id.CHARGE)

	await wait_for_signal(character_behavior.behavior_updated, 1.0, "Wait for next action")
	TestUtils.assert_last_action_not(self, character_behavior, ActionDef.Id.CHARGE)

	# Wait right until cooldown expires and verify we only triggered charge once.
	await wait_seconds(ChargeAction.new().cooldown - 0.1, "Waiting for cooldown to almost expire")
	assert_eq(TestUtils.count_action_triggered(self, character_behavior, ActionDef.Id.CHARGE), 1)
	await wait_seconds(0.2, "Waiting for cooldown to expire")
	assert_eq(TestUtils.count_action_triggered(self, character_behavior, ActionDef.Id.CHARGE), 2)
