extends Node2D

class_name Level

@export var xp: int = 100
@export_group("Tutorial")
# To be used for e.g. tutorial levels in which we may
# want a particular set of skills acquired/unlocked.
# Replaces skill tree state.
@export var skill_tree_state_override: SkillTreeState
# Same as above, but it only adds to existing tree, so
# it's less work if you don't need to remove skills.
@export var skill_tree_state_add: SkillTreeState

@export_group("Testing")
# For testing long level flows, instantly wins level.
@export var instant_win = false
# Only used when running through F6. By default we
# create as many players as starting positions in the
# level, but that's at least 2 as the base level has 2
# and it'd be a pain to change that, so override it here
# as needed.
@export var players = -1
# Used when playing the scene directly.
@export var test_gameplay_characters: Array[GameplayCharacter]
# Provide those separately so you can e.g. load the default
# characters but provide modified behaviors without altering
# their scenes.
@export var test_behaviors: Array[Behavior]

@export_group("Internal")
@export var characters: Node2D
@export var enemies: Node2D
@export var towers: Node2D
@export var spawners: Node2D
@export var starting_positions: Node
var is_frozen: bool = false

# Only for F6.
var gameplay: Node

func _ready():
	# Only when launched with F6.
	if get_parent() == get_tree().root:
		_standalone_ready.call_deferred()

func _standalone_ready():
	# Immediately remove self, we'll test with a copy. Keep parent ref.
	var parent = get_parent()
	get_parent().remove_child(self)

	var level_provider = LevelProvider.new()
	level_provider.levels.append(load(scene_file_path))

	var num_players = players if players != -1 else starting_positions.get_child_count()
	# If setting test characters, must set them all.
	assert(test_gameplay_characters.size() in [0, num_players])
	# Same for behaviors (independently from above).
	assert(test_behaviors.size() in [0, num_players])
	gameplay = load("res://gameplay.tscn").instantiate()
	if not test_gameplay_characters:
		var gcs: Array[GameplayCharacter] = []
		for i in range(num_players):
			var gc = load("res://character/playable_characters/godric_the_knight.tres")
			gcs.append(gc)
		test_gameplay_characters = gcs
	if test_behaviors:
		for i in range(test_gameplay_characters.size()):
			test_gameplay_characters[i].behavior = test_behaviors[i]
	parent.add_child(gameplay)
	gameplay.characters = test_gameplay_characters
	gameplay.level_provider = level_provider
	gameplay.ui_layer.show()
	gameplay.ui_layer.hud.show()
	gameplay.play_next_level()

func initialize(gameplay_characters: Array[GameplayCharacter]):
	for i in gameplay_characters.size():
		if skill_tree_state_add:
			gameplay_characters[i].skill_tree_state.add(skill_tree_state_add)
		if skill_tree_state_override:
			gameplay_characters[i].skill_tree_state = skill_tree_state_override
		var character = gameplay_characters[i].make_character_body()
		character.actor_name = gameplay_characters[i].name
		character.name = character.actor_name
		character.idx = i
		character.peer_id = gameplay_characters[i].peer_id
		character.position = starting_positions.get_child(i).position
		characters.add_child(character)

func start():
	var victory_loss = Component.get_victory_loss_condition_component_or_die(self)
	if instant_win:
		victory_loss.victory.append(VictoryLossConditionComponent.VictoryType.TIME)
		victory_loss.time = 0.1
	victory_loss.level_started()
	_run()

func _run():
	_run_nodes(characters.get_children())
	_run_nodes(enemies.get_children())
	_run_nodes(towers.get_children())
	_run_nodes(spawners.get_children())

func _run_nodes(nodes: Array):
	for node in nodes:
		node.run()
