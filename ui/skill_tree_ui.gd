extends Control

var character: GameplayCharacter
var skill_tree_state: SkillTreeState

@onready var _tabs = %Trees as TabContainer

# TODO: Move (to Skill?) to use elsewhere
var _skill_colors = {
	Skill.SkillType.ACTION: Color.DARK_RED,
	Skill.SkillType.CONDITION: Color.BLUE_VIOLET,
	Skill.SkillType.TARGET: Color.GREEN_YELLOW,
}

signal ok_pressed

@export_group("Testing")
@export var test_character: GameplayCharacter
@export var test_show_all: bool

@export_group("Debug")
@export var selected_node: GraphNode
@export var selected_skill: Skill

# Do something better later.
var purchase_cost = 50
var available_upgrades: int
var hide_locked_skills: bool

func _ready():
	# Only when launched with F6.
	if get_parent() == get_tree().root:
		# So it works as a standalone scene for easy testing.
		if test_character:
			initialize(test_character, test_show_all)
	_setup_tree()

func initialize(gameplay_character: GameplayCharacter, show_all: bool):
	character = gameplay_character
	skill_tree_state = character.skill_tree_state
	hide_locked_skills = not show_all

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

	_tabs.tab_changed.connect(_on_tab_changed)
	for t in skill_tree_state.skill_tree_collection.skill_trees:
		var seen := {}
		# TODO: The graph should be an instanced scene, probably
		var graph = GraphEdit.new()
		graph.show_grid = false
		graph.show_menu = false
		graph.minimap_enabled = true
		graph.panning_scheme = GraphEdit.SCROLL_PANS
		graph.name = SkillTree.TreeType.keys()[t.tree_type]
		graph.set_meta("tree_type", t.tree_type)
		_tabs.add_child(graph)
		for s in t.skills:
			if hide_locked_skills and not skill_tree_state.unlocked(s):
				continue
			var skill = GraphNode.new()
			# var skill = skill_node_scene.instantiate()
			skill.set_meta("skill", s)
			skill.self_modulate = _tint(s)
			skill.draggable = false
			skill.title = s.name()
			skill.get_titlebar_hbox().add_child(_avail_icon(s))

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
	_update_purchase_state()

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

func _avail_icon(skill: Skill) -> TextureRect:
	var out = TextureRect.new()
	# TODO: enum
	match _skill_state(skill):
		# TODO: Move these to exports when nodes become their own scene.
		"Owned":
			out.texture = preload("res://ui/icons/CheckBox.svg")
			# Mute a bit so it's less attention grabbing than available.
			out.self_modulate = Color.DARK_GRAY
		"Locked":
			out.texture = preload("res://ui/icons/Lock.svg")
			out.self_modulate = Color.DARK_GRAY
		"Need Parent":
			out.texture = preload("res://ui/icons/Unlinked.svg")
			out.self_modulate = Color.LIGHT_GREEN
		"Need XP":
			out.texture = preload("res://ui/icons/Unlock.svg")
			out.self_modulate = Color.DARK_GRAY
		"Available":
			out.texture = preload("res://ui/icons/Unlock.svg")
			out.self_modulate = Color.LIGHT_GREEN
		_:
			assert(false, "unrecognized skill state")

	out.size = Vector2(16, 16)
	out.stretch_mode = TextureRect.STRETCH_KEEP
	out.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	out.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return out

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
	ok_pressed.emit()

func _on_buy_button_pressed():
	assert(character.has_xp(purchase_cost), "should not happen")
	character.use_xp(purchase_cost)
	skill_tree_state.acquire(selected_skill)
	selected_node.self_modulate = _tint(selected_skill)
	_update_info_panel(selected_skill)
	_update_purchase_state()

func _update_purchase_state():
	%Status.text = "XP: %d" % character.xp

	var total_count = 0
	for tab in _tabs.get_children():
		var can_purchase_count = 0
		for node in tab.get_children():
			var s = node.get_meta("skill")
			if _can_purchase(s):
				can_purchase_count += 1
			# We may have satisfied prereqs or run out of XP after a purchase,
			# so we update icons for the whole graph.
			_update_node_icon(node, s)
		# TODO: Make this a nice thing.
		var graph_name = SkillTree.TreeType.keys()[tab.get_meta('tree_type')]
		if can_purchase_count > 0:
			graph_name += " (%d)" % can_purchase_count
		tab.name = graph_name
		total_count += can_purchase_count
	available_upgrades = total_count

func _update_node_icon(node: GraphNode, skill: Skill):
	var titlebar = node.get_titlebar_hbox()
	var old = titlebar.get_child(1)
	old.replace_by(_avail_icon(skill))
	old.queue_free()

func _on_tab_changed(_tab: int):
	if selected_node:
		selected_node.selected = false
	_update_info_panel(null)
