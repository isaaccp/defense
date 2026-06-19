extends GutTest

func test_add_stat_adds_to_global_and_character():
	var stats = AggregateStats.new()
	stats.add_stat(Stat.make(Stat.DamageDealt, 100), Enum.CharacterSceneId.KNIGHT)
	
	assert_eq(stats.aggregate.get_value(Stat.DamageDealt), 100)
	assert_true(stats.character_stats.has(Enum.CharacterSceneId.KNIGHT))
	assert_eq(stats.character_stats[Enum.CharacterSceneId.KNIGHT].get_value(Stat.DamageDealt), 100)

func test_add_stat_unspecified_character_only_adds_to_global():
	var stats = AggregateStats.new()
	stats.add_stat(Stat.make(Stat.LevelsBeaten, 1))
	
	assert_eq(stats.aggregate.get_value(Stat.LevelsBeaten), 1)
	assert_false(stats.character_stats.has(Enum.CharacterSceneId.KNIGHT))

func test_add_character_stat_only_adds_to_character():
	var stats = AggregateStats.new()
	stats.add_character_stat(Stat.make(Stat.RunsCompleted, 1), Enum.CharacterSceneId.KNIGHT)
	
	# Global should be unaffected
	assert_eq(stats.aggregate.get_value(Stat.RunsCompleted), 0)
	assert_true(stats.character_stats.has(Enum.CharacterSceneId.KNIGHT))
	assert_eq(stats.character_stats[Enum.CharacterSceneId.KNIGHT].get_value(Stat.RunsCompleted), 1)

func test_add_merges_character_stats_correctly():
	var stats1 = AggregateStats.new()
	stats1.add_character_stat(Stat.make(Stat.RunsCompleted, 1), Enum.CharacterSceneId.KNIGHT)
	
	var stats2 = AggregateStats.new()
	stats2.add_character_stat(Stat.make(Stat.RunsCompleted, 1), Enum.CharacterSceneId.KNIGHT)
	stats2.add_character_stat(Stat.make(Stat.RunsCompleted, 1), Enum.CharacterSceneId.CLERIC)
	
	stats1.add(stats2)
	
	assert_eq(stats1.character_stats[Enum.CharacterSceneId.KNIGHT].get_value(Stat.RunsCompleted), 2)
	assert_eq(stats1.character_stats[Enum.CharacterSceneId.CLERIC].get_value(Stat.RunsCompleted), 1)
