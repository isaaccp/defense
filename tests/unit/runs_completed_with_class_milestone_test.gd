extends GutTest

func test_evaluate_returns_zero_when_character_stats_missing():
	var milestone = preload("res://milestones/runs_completed_with_class_milestone.gd").new()
	var arr: Array[Enum.CharacterSceneId] = [Enum.CharacterSceneId.KNIGHT]
	milestone.required_classes = arr
	milestone.required_count = 1
	
	var global_stats = AggregateStats.new()
	# KNIGHT is not in global_stats
	
	assert_eq(milestone.evaluate(null, null, global_stats), 0)

func test_evaluate_returns_zero_when_runs_completed_is_less_than_required():
	var milestone = preload("res://milestones/runs_completed_with_class_milestone.gd").new()
	var arr: Array[Enum.CharacterSceneId] = [Enum.CharacterSceneId.KNIGHT]
	milestone.required_classes = arr
	milestone.required_count = 2
	
	var global_stats = AggregateStats.new()
	global_stats.add_character_stat(Stat.make(Stat.RunsCompleted, 1), Enum.CharacterSceneId.KNIGHT)
	
	assert_eq(milestone.evaluate(null, null, global_stats), 0)

func test_evaluate_returns_required_count_when_condition_met():
	var milestone = preload("res://milestones/runs_completed_with_class_milestone.gd").new()
	var arr: Array[Enum.CharacterSceneId] = [Enum.CharacterSceneId.KNIGHT]
	milestone.required_classes = arr
	milestone.required_count = 1
	
	var global_stats = AggregateStats.new()
	global_stats.add_character_stat(Stat.make(Stat.RunsCompleted, 1), Enum.CharacterSceneId.KNIGHT)
	
	assert_eq(milestone.evaluate(null, null, global_stats), 1)

func test_evaluate_requires_all_classes():
	var milestone = preload("res://milestones/runs_completed_with_class_milestone.gd").new()
	var arr: Array[Enum.CharacterSceneId] = [Enum.CharacterSceneId.KNIGHT, Enum.CharacterSceneId.CLERIC]
	milestone.required_classes = arr
	milestone.required_count = 1
	
	var global_stats = AggregateStats.new()
	global_stats.add_character_stat(Stat.make(Stat.RunsCompleted, 1), Enum.CharacterSceneId.KNIGHT)
	
	# Missing CLERIC
	assert_eq(milestone.evaluate(null, null, global_stats), 0)
	
	# Add CLERIC
	global_stats.add_character_stat(Stat.make(Stat.RunsCompleted, 1), Enum.CharacterSceneId.CLERIC)
	assert_eq(milestone.evaluate(null, null, global_stats), 1)
