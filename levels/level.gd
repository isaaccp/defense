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
# Used when plaing the scene directly.
@export var test_behavior: Behavior


@export_group("Internal")
@export var characters: Node2D
@export var enemies: Node2D
@export var towers: Node2D
@export var spawners: Node2D
@export var starting_positions: Node
var is_frozen: bool = false

func _ready():
	# Only when launched with F6.
	if get_parent() == get_tree().root:
		if not test_behavior:
			test_behavior = Behavior.new()
		var gameplay = load("res://gameplay.tscn").instantiate()
		gameplay.level = self
		var gcs: Array[GameplayCharacter] = []
		var num_players = players if players != -1 else starting_positions.get_child_count()
		for i in range(num_players):
			var gc = GameplayCharacter.make(Enum.CharacterId.KNIGHT)
			gc.behavior = test_behavior.duplicate(true)
			gcs.append(gc)
		gameplay.characters = gcs
		# If not overriden, unlock all skills when playing stand-alone.
		if not skill_tree_state_override:
			skill_tree_state_override = SkillTreeState.new()
			skill_tree_state_override.full_acquired = true
			skill_tree_state_override.full_acquired = true
		initialize(gcs)
		add_child(gameplay)
		gameplay.ui_layer.show()
		gameplay.ui_layer.hud.show()
		gameplay.play_level()

func initialize(gameplay_characters: Array[GameplayCharacter]):
	for i in gameplay_characters.size():
		if skill_tree_state_add:
			gameplay_characters[i].skill_tree_state.add(skill_tree_state_add)
		if skill_tree_state_override:
			gameplay_characters[i].skill_tree_state = skill_tree_state_override
		var character = CharacterManager.make_character(gameplay_characters[i])
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
