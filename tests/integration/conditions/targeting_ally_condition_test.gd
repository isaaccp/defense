extends GutTest

const basic_test_level_scene = preload("res://tests/integration/actions/basic_test_level.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")

const sword_attack = preload("res://skill_tree/actions/sword_attack.tres")
const enemy_target = preload("res://skill_tree/targets/enemy.tres")
const targeting_ally = preload("res://skill_tree/conditions/targeting_ally.tres")

var level: Level
var character: Node2D
var character_behavior: BehaviorComponent
var enemy: Node2D
var enemy_bc: BehaviorComponent
var enemy_hurtbox: HurtboxComponent

func make_behavior() -> StoredBehavior:
	var condition = StoredParamSkill.new()
	condition.name = targeting_ally.skill_name
	condition.skill_type = Skill.SkillType.CONDITION
	condition.params = SkillParams.new()
	
	var action = StoredParamSkill.new()
	action.name = sword_attack.skill_name
	action.skill_type = Skill.SkillType.ACTION
	action.params = SkillParams.new()
	
	var target = StoredParamSkill.new()
	target.name = enemy_target.skill_name
	target.skill_type = Skill.SkillType.TARGET
	target.params = SkillParams.new()
	target.params.set_placeholder_value(SkillParams.PlaceholderId.SORT, preload("res://skill_tree/target_sorts/closest_first.tres"))
	
	var behavior = StoredBehavior.new()
	behavior.stored_rules.append(RuleDef.make(target, action, condition))
	return behavior

func before_each():
	level = basic_test_level_scene.instantiate()
	level.initialize([test_character])
	add_child_autoqfree(level)
	character = level.characters.get_child(0)
	character_behavior = Component.get_or_die(character, BehaviorComponent.component) as BehaviorComponent
	
	enemy = level.enemies.get_child(0)
	enemy_bc = Component.get_or_die(enemy, BehaviorComponent.component) as BehaviorComponent
	enemy_bc.stored_behavior = StoredBehavior.new()
	enemy_hurtbox = Component.get_or_die(enemy, HurtboxComponent.component) as HurtboxComponent

func test_fails_when_enemy_idle():
	TestUtils.set_character_behavior(character, make_behavior())
	enemy.position = character.position + Vector2.RIGHT * 40
	level.start()

	watch_signals(character_behavior)
	watch_signals(enemy_hurtbox)
	await wait_seconds(1, "Waiting to confirm no hit")
	
	assert_signal_not_emitted(character_behavior, "behavior_updated")
	assert_signal_not_emitted(enemy_hurtbox, "hit")

func test_passes_when_enemy_targets_hero():
	TestUtils.set_character_behavior(character, make_behavior())
	enemy.position = character.position + Vector2.RIGHT * 40
	level.start()

	# Force enemy to target the character
	var forced_target = Target.new()
	forced_target.type = Target.Type.ACTOR
	forced_target.actor = character
	enemy_bc.target = forced_target

	watch_signals(character_behavior)
	watch_signals(enemy_hurtbox)
	await wait_for_signal(enemy_hurtbox.hit, 2, "Waiting for hit")
	
	assert_signal_emitted(character_behavior, "behavior_updated")
	assert_signal_emitted(enemy_hurtbox, "hit")
