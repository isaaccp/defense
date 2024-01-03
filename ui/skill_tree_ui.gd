extends Control

var character: GameplayCharacter
var skill_tree_state: SkillTreeState

# TODO: Move (to Skill?) to use elsewhere
var _skill_colors = {
	Skill.SkillType.ACTION: Color.DARK_RED,
	Skill.SkillType.CONDITION: Color.BLUE_VIOLET,
	Skill.SkillType.TARGET: Color.GREEN_YELLOW,
}

signal ok_pressed

@export_group("Testing")
@export var test_character: GameplayCharacter

@export_group("Debug")
@export var selected_node: GraphNode
@export var selected_skill: Skill

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

func _tint(s: Skill) -> Color:
	var type_mod = Color.WHITE
	if s.skill_type in _skill_colors:
		type_mod = _skill_colors[s.skill_type]
	if not skill_tree_state.acquired(s):
		if _can_purchase(s): # Interesting to buy
			return type_mod.lightened(0.5)
		elif skill_tree_state.unlocked(s): # Save up for
			return type_mod.lightened(0.25)
		else: # Future
			return type_mod * Color.DARK_GRAY
	# Owned
	return type_mod.darkened(0.25)

func _setup_tree():
	%Title.text = "%s: Skill Tree" % character.name

	var tabs = %Trees as TabContainer
	tabs.tab_changed.connect(_on_tab_changed)
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
			var skill = GraphNode.new()
			# var skill = skill_node_scene.instantiate()
			skill.set_meta("skill", s)
			skill.self_modulate = _tint(s)
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

func _skill_state(skill: Skill) -> String:
	if skill_tree_state.acquired(skill):
		return "Owned"
	if not skill_tree_state.unlocked(skill):
		return "Locked"
	if skill.parent and not skill_tree_state.acquired(skill.parent):
		return "Need Parent"
	if not character.has_xp(purchase_cost):
		return "Need XP"
	return "Available"

func _on_node_entered(node: GraphNode, skill: Skill):
	node.self_modulate = Color.WHITE

func _on_node_exited(node: GraphNode, skill: Skill):
	node.self_modulate = _tint(skill)

func _on_node_selected(n: Node):
	if selected_node:
		selected_node.selected = false
	selected_node = n
	selected_skill = n.get_meta("skill")
	_update_info_panel(selected_skill)

func _update_info_panel(skill: Skill):
	if not skill:
		%BuyButton.disabled = true
		%Info.text = "Select a skill..."
		return
	%BuyButton.disabled = not _can_purchase(skill)
	%Info.text = "Name: %s\nType: %s\nState: %s\n..." % [
		skill.name(), skill.type_name(), _skill_state(skill)]

func _on_ok_pressed():
	if force_acquire_all_upgrades and available_upgrades > 0:
		# TODO: The UI seems like a weird place for this check.
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
	selected_node.self_modulate = _tint(selected_skill)
	_update_info_panel(selected_skill)
	_update_can_purchase_counts()

func _update_can_purchase_counts():
	%Status.text = "XP: %d" % character.xp

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

func _on_tab_changed(_tab: int):
	if selected_node:
		selected_node.selected = false
	_update_info_panel(null)
