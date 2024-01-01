extends GutTest

const basic_tower_test_level_scene = preload("res://tests/level/basic_tower_test_level.tscn")
const reach_position_scene = preload("res://tests/level/reach_position_test_level.tscn")

const move_sword_behavior = preload("res://behavior/resources/basic_move_plus_sword_attack.tres")

class LevelTest extends GutTest:
	var level: Level
	var scene: PackedScene

	
	func before_each():
		level = scene.instantiate()
		level.initialize([
			GameplayCharacter.make_gameplay_character(Enum.CharacterId.KNIGHT),
			GameplayCharacter.make_gameplay_character(Enum.CharacterId.KNIGHT),
		])

	func set_character_behaviors(behavior0: Behavior, behavior1: Behavior):
		var character0 = level.characters.get_child(0)
		var character1 = level.characters.get_child(1)
		Component.get_behavior_component_or_die(character0).behavior = behavior0
		Component.get_behavior_component_or_die(character1).behavior = behavior1

class TestTowerEnemyDestructionConditions extends LevelTest:

	var tower: Node2D
	var tower_health: HealthComponent
		
	func before_each():
		scene = basic_tower_test_level_scene
		super()
		add_child_autoqfree(level)
		set_character_behaviors(move_sword_behavior, move_sword_behavior)
		# Set up tower.
		tower = level.towers.get_child(0)
		tower_health = Component.get_health_component_or_die(tower)
		
	func test_tower_destruction_fails_level():
		await wait_for_signal(level.level_failed, 3, "Waiting for level to fail")
		assert_signal_emitted(level, "level_failed")

	func test_enemy_destruction_finishes_level():
		# Drop enemies on top of characters so they are easily dispatched.
		level.enemies.get_child(0).position = level.characters.get_child(0).position + Vector2.RIGHT * 50
		level.enemies.get_child(1).position = level.characters.get_child(1).position + Vector2.RIGHT * 50
		await wait_for_signal(level.level_finished, 5, "Waiting for level to finish")
		assert_signal_emitted(level, "level_finished")

class TestPositionReachedConditions extends LevelTest:
	func make_move_behavior() -> Behavior:
		var behavior = Behavior.new()
		behavior.rules.append(
			Rule.make(
				TargetSelectionDef.make(TargetSelectionDef.Id.TOWER),
				ActionDef.make(ActionDef.Id.MOVE_TO),
			)
		)
		return behavior
		
	func before_each():
		scene = reach_position_scene
		super()
	
	func set_victory_type(victory_type: VictoryLossConditionComponent.VictoryType):
		var victory = Component.get_or_die(level, VictoryLossConditionComponent.component) as VictoryLossConditionComponent
		var victory_types: Array[VictoryLossConditionComponent.VictoryType] = [victory_type]
		victory.victory = victory_types
		
	func test_one_reach_position_victory():
		set_victory_type(VictoryLossConditionComponent.VictoryType.ONE_REACH_POSITION)
		add_child_autoqfree(level)
		set_character_behaviors(Behavior.new(), make_move_behavior())
		await wait_for_signal(level.level_finished, 3, "Waiting for level to finish")
		assert_signal_emitted(level, "level_finished")

	func test_all_reach_position_fail():
		set_victory_type(VictoryLossConditionComponent.VictoryType.ALL_REACH_POSITION)
		add_child_autoqfree(level)
		set_character_behaviors(Behavior.new(), make_move_behavior())
		await wait_for_signal(level.level_finished, 3, "Waiting for level to NOT finish")
		assert_signal_not_emitted(level, "level_finished")

	func test_all_reach_position_victory():
		set_victory_type(VictoryLossConditionComponent.VictoryType.ALL_REACH_POSITION)
		add_child_autoqfree(level)
		set_character_behaviors(make_move_behavior(), make_move_behavior())
		await wait_for_signal(level.level_finished, 3, "Waiting for level to NOT finish")
		assert_signal_emitted(level, "level_finished")
