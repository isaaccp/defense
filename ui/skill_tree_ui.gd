extends Control

class_name SkillTreeUI

const skill_tree_collection = preload("res://skill_tree/trees/skill_tree_collection.tres")

enum Mode {
	ACQUIRE,
	UNLOCK,
}

var mode: Mode
var save_state: SaveState
var unlocked_skills: SkillTreeState
var character: GameplayCharacter
var acquired_skills: SkillTreeState

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
		# TODO: Update so it works and so you can test both modes.
		#if test_character:
		#	initialize(test_character, test_show_all)
		pass
	_setup_tree()

func initialize(mode: Mode, save_state: SaveState, character: GameplayCharacter = null, show_all: bool = false):
	assert(save_state)
	if mode == Mode.ACQUIRE:
		assert(character)
	self.mode = mode
	self.save_state = save_state
	self.character = character
	unlocked_skills = save_state.unlocked_skills
	assert(unlocked_skills)
	if character:
		acquired_skills = character.acquired_skills
		assert(acquired_skills)
	hide_locked_skills = not show_all

func _tint(s: Skill) -> Color:
	var type_mod = Color.WHITE
	if s.skill_type in _skill_colors:
		type_mod = _skill_colors[s.skill_type]
	if mode == Mode.UNLOCK:
		if not unlocked_skills.available(s):
			if _can_unlock(s):
				return type_mod.lightened(0.5)
			else:
				return type_mod * Color.DARK_GRAY
	else:
		if not acquired_skills.available(s):
			if _can_purchase(s): # Interesting to buy
				return type_mod.lightened(0.5)
			elif unlocked_skills.available(s): # Save up for
				return type_mod.lightened(0.25)
			else: # Future
				return type_mod * Color.DARK_GRAY
	# Owned
	return type_mod.darkened(0.25)

func _setup_tree():
	# TODO: Pass text.
	%Title.text = "Skill Tree"
	if mode == Mode.ACQUIRE:
		%BuyButton.text = "Buy"
	else:
		%BuyButton.text = "Unlock"
	_tabs.tab_changed.connect(_on_tab_changed)
	for t in skill_tree_collection.skill_trees:
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
			if mode == Mode.ACQUIRE and hide_locked_skills:
				if not unlocked_skills.available(s):
					continue
			elif mode == Mode.UNLOCK and hide_locked_skills:
				if s.parent and not unlocked_skills.available(s.parent):
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
				var parent = seen.get(s.parent) as GraphNode
				if not parent:
					print("Skill %s parent %s not found in tree %s" % [s, s.parent, t.tree_type])
					continue
				var child = seen[s] as GraphNode
				parent.set_slot_enabled_right(0, true)
				child.set_slot_enabled_left(0, true)
				graph.connect_node(parent.name, parent.get_output_port_slot(0), child.name, child.get_input_port_slot(0))
		graph.arrange_nodes()
		graph.node_selected.connect(_on_node_selected)
	_update_purchase_state()

func _can_purchase(skill: Skill) -> bool:
	if acquired_skills.available(skill):
		return false
	if not unlocked_skills.available(skill):
		return false
	if skill.parent and not acquired_skills.available(skill.parent):
		return false
	if not character.has_xp(purchase_cost):
		return false
	return true

func _can_unlock(skill: Skill) -> bool:
	if unlocked_skills.available(skill):
		return false
	if skill.parent and not unlocked_skills.available(skill.parent):
		return false
	# TODO: Check meta-xp.
	return true

func _skill_state(skill: Skill) -> String:
	if mode == Mode.ACQUIRE:
		if acquired_skills.available(skill):
			return "Owned"
		if not unlocked_skills.available(skill):
			return "Locked"
		if skill.parent and not acquired_skills.available(skill.parent):
			return "Need Parent"
		if not character.has_xp(purchase_cost):
			return "Need XP"
		return "Available"
	else:
		if unlocked_skills.available(skill):
			return "Unlocked"
		if skill.parent and not unlocked_skills.available(skill.parent):
			return "Need Parent"
		# TODO: Check SaveState for enough meta-XP.
		return "Unlockable"

func _avail_icon(skill: Skill) -> TextureRect:
	var out = TextureRect.new()
	# TODO: enum
	match _skill_state(skill):
		# TODO: Move these to exports when nodes become their own scene.
		"Owned", "Unlocked":
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
		"Available", "Unlockable":
			out.texture = preload("res://ui/icons/Unlock.svg")
			out.self_modulate = Color.LIGHT_GREEN
		_:
			assert(false, "unrecognized skill state")

	out.size = Vector2(16, 16)
	out.stretch_mode = TextureRect.STRETCH_KEEP
	out.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	out.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return out

func _on_node_entered(node: GraphNode, _skill: Skill):
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
	if mode == Mode.UNLOCK:
		%BuyButton.disabled = not _can_unlock(skill)
	else:
		%BuyButton.disabled = not _can_purchase(skill)
	%Info.text = "Name: %s\nType: %s\nState: %s\n..." % [
		skill.name(), skill.type_name(), _skill_state(skill)]

func _on_ok_pressed():
	ok_pressed.emit()

func _on_buy_button_pressed():
	if mode == Mode.ACQUIRE:
		assert(character.has_xp(purchase_cost), "should not happen")
		character.use_xp(purchase_cost)
		acquired_skills.mark_available(selected_skill)
	else:
		# TODO: Check meta-XP and use it.
		unlocked_skills.mark_available(selected_skill)
	selected_node.self_modulate = _tint(selected_skill)
	_update_info_panel(selected_skill)
	_update_purchase_state()

func _update_purchase_state():
	if mode == Mode.ACQUIRE:
		%Status.text = "XP: %d" % character.xp
	else:
		# TODO: Update from meta-xp in SaveState.
		pass

	var total_count = 0
	for tab in _tabs.get_children():
		var available_count  = 0
		for node in tab.get_children():
			var s = node.get_meta("skill")
			if mode == Mode.ACQUIRE and _can_purchase(s):
				available_count += 1
			elif mode == Mode.UNLOCK and _can_unlock(s):
				available_count += 1
			# We may have satisfied prereqs or run out of XP after a purchase,
			# so we update icons for the whole graph.
			_update_node_icon(node, s)
		# TODO: Make this a nice thing.
		var graph_name = SkillTree.TreeType.keys()[tab.get_meta('tree_type')]
		if available_count > 0:
			graph_name += " (%d)" % available_count
		tab.name = graph_name
		total_count += available_count
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
