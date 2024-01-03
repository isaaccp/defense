extends Control

var character: GameplayCharacter
var skill_tree_state: SkillTreeState
var _skills: Dictionary # GraphNode name -> Skill resource

signal ok_pressed

@export_group("Testing")
@export var test_character: GameplayCharacter

func _ready():
	# Only when launched with F6.
	if get_parent() == get_tree().root:
		# So it works as a standalone scene for easy testing.
		if test_character:
			initialize(test_character)
	_setup_tree()

func initialize(gameplay_character: GameplayCharacter):
	character = gameplay_character
	skill_tree_state = character.skill_tree_state

func _setup_tree():
	%Title.text = "%s: Skill Tree" % character.name
	%Status.text = "XP: %d" % character.xp
	# FIXME: Mark acquired skills from state.
	var tabs = %Trees as TabContainer
	for t in skill_tree_state.skill_tree_collection.skill_trees:
		var seen: Dictionary
		# TODO: The graph should be an instanced scene, probably
		var graph = GraphEdit.new()
		graph.show_grid = false
		graph.show_menu = false
		graph.minimap_enabled = false
		graph.panning_scheme = GraphEdit.SCROLL_PANS
		graph.name = SkillTree.TreeType.keys()[t.tree_type]
		tabs.add_child(graph)
		for s in t.skills:
			if not skill_tree_state.unlocked(s):
				continue
			var skill = GraphNode.new()
			skill.draggable = false
			skill.title = s.name()
			var icon = TextureRect.new()
			# FIXME: Just a placeholder. GraphNode wants some content to associate connection ports with.
			icon.texture = preload("res://assets/kyrises_rpg_icon_pack/icons/48x48/book_02a.png")
			icon.stretch_mode = TextureRect.STRETCH_KEEP
			skill.add_child(icon)
			graph.add_child(skill)
			seen[s] = skill
			_skills[skill.name] = s
		for s in seen:
			# Have to do this in a second pass because we don't necessarily
			# see children after their parents.
			if s.parent:
				var parent = seen[s.parent] as GraphNode
				var child = seen[s] as GraphNode
				parent.set_slot_enabled_right(0, true)
				child.set_slot_enabled_left(0, true)
				graph.connect_node(parent.name, parent.get_output_port_slot(0), child.name, child.get_input_port_slot(0))
		graph.arrange_nodes()
		graph.node_selected.connect(_on_node_selected)

func _on_node_selected(n: Node):
	var skill = _skills[n.name] as Skill
	%Info.text = "Name: %s\nType: %s\n..." % [skill.name(), skill.type_name()]

func _on_ok_pressed():
	ok_pressed.emit()
