extends GutTest

const empty_level_scene = preload("res://tests/integration/actions/empty_level.tscn")
var test_character = preload("res://character/playable_characters/test_character.tres")

static func get_enemy_scenes() -> Array:
	var result = []
	var base_dir = DirAccess.open("res://enemies")
	if not base_dir:
		return result
	base_dir.list_dir_begin()
	var entry = base_dir.get_next()
	while entry != "":
		if base_dir.current_is_dir() and not entry.begins_with("."):
			var subdir = DirAccess.open("res://enemies/%s" % entry)
			if subdir:
				subdir.list_dir_begin()
				var file = subdir.get_next()
				while file != "":
					if file.ends_with(".tscn"):
						result.append(["res://enemies/%s/%s" % [entry, file]])
					file = subdir.get_next()
		entry = base_dir.get_next()
	return result

func test_enemy_smoke(params=use_parameters(get_enemy_scenes())):
	var scene_path: String = params[0]

	var packed = load(scene_path) as PackedScene
	assert_not_null(packed, "Could not load %s" % scene_path)
	if not packed:
		return

	test_character.initialize("test_character", 1)
	var level = empty_level_scene.instantiate() as Level
	level.initialize([test_character])
	add_child_autoqfree(level)

	var character = level.characters.get_child(0)
	TestUtils.set_character_behavior(character, StoredBehavior.new())

	var enemy = packed.instantiate()
	level.enemies.add_child(enemy)
	enemy.position = character.position + Vector2.RIGHT * 100

	var behavior := Component.get_or_null(enemy, BehaviorComponent.component) as BehaviorComponent
	if not behavior or not behavior.stored_behavior or behavior.stored_behavior.stored_rules.is_empty():
		return

	level.start()
	watch_signals(behavior)
	await wait_for_signal(behavior.behavior_updated, 3.0, "%s should pick an action" % scene_path)
	assert_signal_emitted(behavior, "behavior_updated")
