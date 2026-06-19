extends Resource

class_name AggregateStats

@export var aggregate: Stats
# Dictionary from Enum.CharacterSceneId to Stats
@export var character_stats: Dictionary[Enum.CharacterSceneId, Stats] = {}

func _init():
	aggregate = Stats.new()

func add_stat(stat: Stat, character_id: Enum.CharacterSceneId = Enum.CharacterSceneId.UNSPECIFIED):
	aggregate.add_stat(stat)
	if character_id != Enum.CharacterSceneId.UNSPECIFIED:
		if not character_stats.has(character_id):
			character_stats[character_id] = Stats.new()
		character_stats[character_id].add_stat(stat)

func add(other: AggregateStats):
	aggregate.add(other.aggregate)
	for character_id in other.character_stats:
		if not character_stats.has(character_id):
			character_stats[character_id] = Stats.new()
		character_stats[character_id].add(other.character_stats[character_id])

func get_value(name: StringName):
	return aggregate.get_value(name)
