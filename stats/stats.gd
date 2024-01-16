extends Resource

class_name Stats

@export var stats: Dictionary

func add_stat(stat: Stat):
	if stat.name in stats:
		stats[stat.name] += stat.value
	else:
		stats[stat.name] = stat.value

func add(other: Stats):
	for stat_name in other.stats:
		var stat = Stat.make(stat_name, other.stats[stat_name])
		add_stat(stat)

func get_value(name: StringName):
	return stats.get(name, 0)

func _to_string():
	var s = ""
	for key in stats.keys():
		s += "%s: %s\n" % [key, stats[key]]
	return s
