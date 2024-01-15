extends PanelContainer

class_name LevelSummary

const stats_view_scene = preload("res://ui/stats_view.tscn")
const stat_names: Array[StringName] = [
	Stat.EnemiesDestroyed,
	Stat.DamageDealt,
	Stat.DamageHealed,
]

func prepare(character_node: Node):
	# Clear placeholders.
	for c in %StatsContainer.get_children():
		c.queue_free()
	for character in character_node.get_children():
		assert(character is Character)
		var logging_component = Component.get_logging_component_or_die(character)
		var stats = logging_component.stats
		var stats_view: StatsView = stats_view_scene.instantiate()
		stats_view.initialize("Stats for %s" % character.actor_name, stat_names, stats)
		%StatsContainer.add_child(stats_view)
