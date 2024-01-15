extends RefCounted

class_name Stats

var stats: Dictionary

func add_stat(stat: Stat):
	if stat.name in stats:
		stats[stat.name] += stat.value
	else:
		stats[stat.name] = stat.value

func get_value(name: StringName):
	return stats.get(name, 0)

func all()-> Array[StringName]:
	var stat_names: Array[StringName]
	stat_names.assign(stats.keys())
	return stat_names
