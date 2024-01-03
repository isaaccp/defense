extends Control

var character: GameplayCharacter
var skill_tree_state: SkillTreeState

# TODO: Move (to Skill?) to use elsewhere
var _skill_colors = {
	Skill.SkillType.ACTION: Color.RED,
	Skill.SkillType.CONDITION: Color.BLUE,
	Skill.SkillType.TARGET: Color.GREEN,
}

signal ok_pressed

@export_group("Testing")
@export var test_character: GameplayCharacter

@export_group("Debug")
@export var selected_node: Node
@export var selected_skill: Skill

# const skill_node_scene = preload("res://ui/skill_node.tscn")


# Do something better later.
var purchase_cost = 50
var available_upgrades: int
var force_acquire_all_upgrades: bool

func _ready():
	# Only when launched with F6.
	if get_parent() == get_tree().root:
		# So it works as a standalone scene for easy testing.
		if test_character:
			initialize(test_character, false)
	_setup_tree()

func initialize(gameplay_character: GameplayCharacter, force_acquire_all: bool):
	character = gameplay_character
	skill_tree_state = character.skill_tree_state
	force_acquire_all_upgrades = force_acquire_all

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
		graph.minimap_enabled = true
		graph.panning_scheme = GraphEdit.SCROLL_PANS
		graph.name = SkillTree.TreeType.keys()[t.tree_type]
		tabs.add_child(graph)
		for s in t.skills:
			# TODO: May need different modes, showing locked or not.
			if not skill_tree_state.unlocked(s):
				continue
			var skill = GraphNode.new()
			# var skill = skill_node_scene.instantiate()
			assert(s.skill_type in _skill_colors)
			skill.self_modulate = _skill_colors[s.skill_type]
			if not skill_tree_state.acquired(s):
				if _can_purchase(s):
					skill.modulate = Color(1, 1, 1, 0.7)
				else:
					skill.modulate = Color(1, 1, 1, 0.25)
			skill.set_meta("modulate", skill.modulate)
			skill.draggable = false
			skill.title = s.name()
			var icon = TextureRect.new()
			# FIXME: Just a placeholder. GraphNode wants some content to associate connection ports with.
			icon.texture = preload("res://assets/kyrises_rpg_icon_pack/icons/48x48/book_02a.png")
			icon.stretch_mode = TextureRect.STRETCH_KEEP
			skill.add_child(icon)
			skill.mouse_entered.connect(_on_node_entered.bind(skill, s))
			skill.mouse_exited.connect(_on_node_exited.bind(skill, s))
			graph.add_child(skill)
			seen[s] = skill
			skill.set_meta("skill", s)
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
	_update_can_purchase_counts()

func _can_purchase(skill: Skill) -> bool:
	if skill_tree_state.acquired(skill):
		return false
	if not skill_tree_state.unlocked(skill):
		return false
	if skill.parent and not skill_tree_state.acquired(skill.parent):
		return false
	if not character.has_xp(purchase_cost):
		return false
	return true

func _on_node_entered(node: GraphNode, skill: Skill):
	node.modulate = Color.WHITE

func _on_node_exited(node: GraphNode, skill: Skill):
	node.modulate = node.get_meta("modulate")

func _on_node_selected(n: Node):
	selected_node = n
	selected_skill = n.get_meta("skill")
	%BuyButton.disabled = not _can_purchase(selected_skill)
	%Info.text = "Name: %s\nType: %s\n..." % [selected_skill.name(), selected_skill.type_name()]

func _on_ok_pressed():
	if force_acquire_all_upgrades and available_upgrades > 0:
		var dialog = AcceptDialog.new()
		dialog.title = "Not so fast!"
		dialog.dialog_text = "In this level, you must purchase all available upgrades before proceeding"
		dialog.always_on_top = true
		dialog.show()
		dialog.popup_exclusive_centered(self)
		await dialog.confirmed
		dialog.queue_free()
	else:
		ok_pressed.emit()

func _on_buy_button_pressed():
	assert(character.has_xp(purchase_cost), "should not happen")
	character.use_xp(purchase_cost)
	skill_tree_state.acquire(selected_skill)
	selected_node.modulate = Color(1, 1, 1, 1)
	selected_node.set_meta("modulate", Color(1, 1, 1, 1))
	%BuyButton.disabled = true
	# TODO: Do this with some signal from character instead.
	%Status.text = "XP: %d" % character.xp
	_update_can_purchase_counts()

func _update_can_purchase_counts():
	var total_count = 0
	var tabs = %Trees as TabContainer
	for i in range(skill_tree_state.skill_tree_collection.skill_trees.size()):
		var t = skill_tree_state.skill_tree_collection.skill_trees[i]
		var can_purchase_count = 0
		for s in t.skills:
			if _can_purchase(s):
				can_purchase_count += 1
		# Make this a nice thing.
		var graph_name = SkillTree.TreeType.keys()[t.tree_type]
		if can_purchase_count > 0:
			graph_name += " (%d)" % can_purchase_count
		tabs.get_child(i).name = graph_name
		total_count += can_purchase_count
	available_upgrades = total_count
