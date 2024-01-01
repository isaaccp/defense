extends Control

var _skills: Dictionary # GraphNode name -> Skill resource

func _ready():
	# Just For testing...
	# FIXME: State contains the collection currently.
	initialize(preload("res://skill_tree/trees/skill_tree_collection.tres"), null)

func initialize(trees: SkillTreeCollection, state: SkillTreeState):
	# FIXME: Use the TreeCollection in state.
	# FIXME: Add param for XP state (per character?).
	# FIXME: Mark acquired skills from state.
	# FIXME: Support re-init
	var tabs = %Trees as TabContainer
	for t in trees.skill_trees:
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
			var skill = GraphNode.new()
			skill.draggable = false
			if s.target_selection_def:
				skill.title = s.target_selection_def.to_string()
			elif s.action_def:
				skill.title = s.action_def.to_string()
			else:
				skill.title = "unrecognized skill type"
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
