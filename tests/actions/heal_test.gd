extends GutTest

# Level has 1 enemy.
const empty_level_scene = preload("res://tests/actions/empty_level.tscn")
const heal_scene = preload("res://behavior/actions/scenes/heal.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")
const heal = preload("res://skill_tree/actions/heal.tres")
const self_target = preload("res://skill_tree/targets/self.tres")

var level: Level
var character: Node2D
var character_behavior: BehaviorComponent
var character_health: HealthComponent
var heal_amount: int

func make_heal_behavior() -> Behavior:
	var behavior = Behavior.new()
	behavior.saved_rules.append(
		RuleDef.make(
			RuleSkillDef.from_skill(self_target),
			RuleSkillDef.from_skill(heal),
		)
	)
	return behavior

func before_all():
	var heal = heal_scene.instantiate()
	heal_amount = -Component.get_or_die(heal, HitboxComponent.component).hit_effect.damage
	heal.free()

func before_each():
	level = empty_level_scene.instantiate()
	level.initialize([test_character])
	add_child_autoqfree(level)
	# Set up character.
	character = level.characters.get_child(0)
	character_behavior = Component.get_behavior_component_or_die(character)
	character_health = Component.get_health_component_or_die(character)

func test_heal_works():
	TestUtils.set_character_behavior(character, make_heal_behavior())

	await wait_frames(1)
	character_health.health = 5

	level.start()
	watch_signals(character_behavior)
	watch_signals(character_health)
	await wait_seconds(0.5, "Waiting for heal")
	assert_signal_emitted(character_behavior, "behavior_updated")
	var health_update = get_signal_parameters(character_health, "health_updated", 0)[0] as HealthComponent.HealthUpdate
	assert_eq(health_update.health - health_update.prev_health, heal_amount)
