extends GutTest

const basic_test_level_scene = preload("res://tests/integration/actions/basic_test_level.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")
const sword_attack = preload("res://skill_tree/actions/sword_attack.tres")
const hero_target = preload("res://skill_tree/targets/enemy.tres")
const closest_first = preload("res://skill_tree/target_sorts/closest_first.tres")
const taunted_status = preload("res://effects/statuses/taunted.tres")

var level: Level
var hero_a: Node2D
var hero_b: Node2D
var enemy: Node2D
var enemy_bc: BehaviorComponent

func make_enemy_behavior() -> StoredBehavior:
	var target = StoredParamSkill.new()
	target.name = hero_target.skill_name
	target.skill_type = Skill.SkillType.TARGET
	target.params = SkillParams.new()
	target.params.set_placeholder_value(SkillParams.PlaceholderId.SORT, closest_first)
	
	var action = StoredParamSkill.new()
	action.name = sword_attack.skill_name
	action.skill_type = Skill.SkillType.ACTION
	action.params = SkillParams.new()
	
	var behavior = StoredBehavior.new()
	behavior.stored_rules.append(RuleDef.make(target, action))
	return behavior

func before_each():
	level = basic_test_level_scene.instantiate()
	# Spawn TWO heroes so we can test intercept
	level.initialize([test_character, test_character])
	add_child_autoqfree(level)
	
	hero_a = level.characters.get_child(0)
	hero_b = level.characters.get_child(1)
	
	# Give them behaviors so they don't error, but we don't care what they do
	var null_behavior = StoredBehavior.new()
	TestUtils.set_character_behavior(hero_a, null_behavior)
	TestUtils.set_character_behavior(hero_b, null_behavior)
	
	enemy = level.enemies.get_child(0)
	enemy_bc = Component.get_or_die(enemy, BehaviorComponent.component) as BehaviorComponent

func test_taunted_intercepts_target():
	enemy_bc.stored_behavior = make_enemy_behavior()
	
	# Position hero_a closer to enemy than hero_b, both in range (40) of sword attack
	hero_a.position = Vector2(20, 0)
	hero_b.position = Vector2(30, 0)
	enemy.position = Vector2(0, 0)
	
	level.start()
	await wait_process_frames(5)
	
	# Assert enemy initially targets the closest hero (hero_a)
	assert_eq(enemy_bc.target.actor, hero_a, "Enemy should target closest hero initially")
	
	# Apply taunted status from hero_b
	var enemy_status = Component.get_or_die(enemy, StatusComponent.component) as StatusComponent
	enemy_status.set_status(&"test_taunt", taunted_status, TauntedParams.make(hero_b), 5.0)
	
	if enemy_bc.action:
		enemy_bc.action.finished = true
	
	await wait_process_frames(5)
	
	# Assert target was hijacked to hero_b
	assert_eq(enemy_bc.target.actor, hero_b, "Enemy target should be hijacked to taunter (hero_b)")
