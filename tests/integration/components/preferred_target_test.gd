extends GutTest

# Covers the preferred-target commitment feature: the BehaviorComponent slot,
# the Set / Clear Preferred Target actions, the Preferred Target selector and
# the world marker.

const basic_test_level_scene = preload("res://tests/integration/actions/basic_test_level.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")

const enemy_target = preload("res://skill_tree/targets/enemy.tres")
const preferred_target_skill = preload("res://skill_tree/targets/preferred_target.tres")
const set_preferred = preload("res://skill_tree/actions/set_preferred_target.tres")
const clear_preferred = preload("res://skill_tree/actions/clear_preferred_target.tres")
const sword_attack = preload("res://skill_tree/actions/sword_attack.tres")

var level: Level
var character: Node2D
var character_behavior: BehaviorComponent
var enemy: Node2D
var enemy_hurtbox: HurtboxComponent

func before_each():
	level = basic_test_level_scene.instantiate()
	level.initialize([test_character])
	add_child_autoqfree(level)
	character = level.characters.get_child(0)
	character_behavior = BehaviorComponent.get_or_die(character)
	enemy = level.enemies.get_child(0)
	enemy.get_component_or_die(BehaviorComponent).stored_behavior = StoredBehavior.new()
	enemy_hurtbox = enemy.get_component_or_die(HurtboxComponent) as HurtboxComponent

func _one_rule_behavior(target: TargetSelectionDef, action: ActionDef) -> StoredBehavior:
	var behavior = StoredBehavior.new()
	behavior.stored_rules.append(TestUtils.rule_def(target, action))
	return behavior

func test_set_and_clear_slot():
	watch_signals(character_behavior)
	character_behavior.set_preferred_target(enemy)
	assert_eq(character_behavior.preferred_target, enemy)
	assert_signal_emitted_with_parameters(
		character_behavior, "preferred_target_changed", [enemy])
	character_behavior.clear_preferred_target("test")
	assert_null(character_behavior.preferred_target)
	assert_signal_emitted_with_parameters(
		character_behavior, "preferred_target_changed", [null])

func test_set_is_idempotent():
	character_behavior.set_preferred_target(enemy)
	watch_signals(character_behavior)
	character_behavior.set_preferred_target(enemy)
	assert_signal_not_emitted(character_behavior, "preferred_target_changed")

func test_marker_spawns_on_preferred_and_despawns():
	character_behavior.set_preferred_target(enemy)
	assert_not_null(enemy.get_node_or_null("PreferredTargetMarker"),
		"Marker should be a child of the committed enemy")
	character_behavior.clear_preferred_target("test")
	await wait_frames(2)
	assert_null(enemy.get_node_or_null("PreferredTargetMarker"),
		"Marker should be gone after clearing")

func test_auto_clears_when_target_destroyed():
	TestUtils.set_character_behavior(character, StoredBehavior.new())
	level.start()
	character_behavior.set_preferred_target(enemy)
	assert_eq(character_behavior.preferred_target, enemy)
	enemy.destroyed = true
	await wait_seconds(0.2, "Waiting for auto-clear")
	assert_null(character_behavior.preferred_target)

func test_set_action_commits_enemy():
	TestUtils.set_character_behavior(
		character, _one_rule_behavior(enemy_target, set_preferred))
	watch_signals(character_behavior)
	level.start()
	await wait_for_signal(character_behavior.preferred_target_changed, 3,
		"Waiting for Set Preferred Target to fire")
	assert_eq(character_behavior.preferred_target, enemy)

func test_clear_action_drops_target():
	TestUtils.set_character_behavior(
		character, _one_rule_behavior(preferred_target_skill, clear_preferred))
	level.start()
	character_behavior.set_preferred_target(enemy)
	await wait_seconds(0.5, "Waiting for Clear Preferred Target to fire")
	assert_null(character_behavior.preferred_target)

func test_sword_to_preferred_skipped_when_uncommitted():
	TestUtils.set_character_behavior(
		character, _one_rule_behavior(preferred_target_skill, sword_attack))
	enemy.position = character.position + Vector2.RIGHT * 40
	level.start()
	watch_signals(enemy_hurtbox)
	await wait_seconds(2, "No commitment -> rule is skipped, no attack")
	assert_signal_not_emitted(enemy_hurtbox, "hit")

func test_sword_to_preferred_works_when_committed():
	TestUtils.set_character_behavior(
		character, _one_rule_behavior(preferred_target_skill, sword_attack))
	enemy.position = character.position + Vector2.RIGHT * 40
	level.start()
	character_behavior.set_preferred_target(enemy)
	watch_signals(enemy_hurtbox)
	await wait_for_signal(enemy_hurtbox.hit, 3, "Committed -> enemy is attacked")
	assert_signal_emitted(enemy_hurtbox, "hit")
