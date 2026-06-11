extends Control

class_name SkillTreeUI

const skill_tree_collection = preload("res://skill_tree/trees/skill_tree_collection.tres")

# Card / layout sizing — referenced from inner classes via SkillTreeUI.*.
const CARD_WIDTH := 150.0
const CARD_HEIGHT := 54.0
const COLUMN_W := CARD_WIDTH + 40.0
const ROW_H := CARD_HEIGHT + 14.0
const TREE_PADDING := 12.0

# Two-axis tinting: each state has a base background hue (what is wrong / what
# you need) and the border color comes from the skill type (action / condition /
# target / sort). State hues:
#   OWNED            — desaturated grey   (already yours)
#   BUYABLE          — bright green       (do it now if you want)
#   NEED_XP          — warm yellow        ("save up")
#   NEED_PARENT      — cool blue          ("walk the path")
#   LOCKED_ADJACENT  — muted purple       ("meta-progression hasn't given you this yet")
#   SHROUDED         — near-black         ("you don't even know what this is")
enum SkillState {
	OWNED,
	BUYABLE,
	NEED_XP,
	NEED_PARENT,
	LOCKED_ADJACENT,
	SHROUDED,
}

const STATE_COLORS := {
	SkillState.OWNED: Color(0.32, 0.32, 0.34, 1.0),
	SkillState.BUYABLE: Color(0.30, 0.65, 0.30, 1.0),
	SkillState.NEED_XP: Color(0.75, 0.62, 0.18, 1.0),
	SkillState.NEED_PARENT: Color(0.28, 0.46, 0.72, 1.0),
	SkillState.LOCKED_ADJACENT: Color(0.50, 0.30, 0.62, 1.0),
	SkillState.SHROUDED: Color(0.10, 0.10, 0.12, 1.0),
}



enum Mode { ACQUIRE, UNLOCK }

var mode: Mode
var save_state: SaveState
var unlocked_skills: SkillTreeState
var character: GameplayCharacter
var acquired_skills: SkillTreeState
var hide_locked_skills: bool = false

# Until we vary cost by skill, one flat number for everything.
var purchase_cost: int = 150

var _panes: Array = []
var _hovered_skill: Skill

signal ok_pressed

@export_group("Testing")
@export var test_mode: Mode
@export var test_character: GameplayCharacter

func _ready() -> void:
	if get_parent() == get_tree().root:
		var ss := SaveState.make_new()
		if test_mode == Mode.UNLOCK:
			ss.meta_xp = 600
			initialize(test_mode, ss)
		elif test_mode == Mode.ACQUIRE:
			ss.unlocked_skills = SkillTreeState.new()
			ss.unlocked_skills.full = true
			assert(test_character)
			initialize(test_mode, ss, test_character)
	_build_tabs()

func initialize(mode_: Mode, save_state_: SaveState, character_: GameplayCharacter = null, show_all: bool = false) -> void:
	assert(save_state_)
	if mode_ == Mode.ACQUIRE:
		assert(character_)
	mode = mode_
	save_state = save_state_
	character = character_
	unlocked_skills = save_state.unlocked_skills
	assert(unlocked_skills)
	if character:
		acquired_skills = character.acquired_skills
		assert(acquired_skills)
	hide_locked_skills = not show_all
	if is_node_ready():
		_build_tabs()

func _build_tabs() -> void:
	if not save_state:
		return  # not initialized yet
	var tabs := %Trees as TabContainer
	for child in tabs.get_children():
		child.queue_free()
	_panes.clear()
	%Title.text = "Skill Tree" if mode == Mode.ACQUIRE else "Unlock Skills"
	for t in skill_tree_collection.skill_trees:
		# Skip META tree in ACQUIRE mode (meta skills are unlocked between runs).
		if mode == Mode.ACQUIRE and t.tree_type == Skill.TreeType.META:
			continue
		var pane := TreePane.new(self, t)
		pane.name = Skill.TreeType.keys()[t.tree_type]
		tabs.add_child(pane)
		_panes.append(pane)
	_refresh()
	hover_skill(null)

func _refresh() -> void:
	for pane in _panes:
		pane.refresh()
	_refresh_status()
	_refresh_tab_badges()

func _refresh_status() -> void:
	if mode == Mode.ACQUIRE:
		%Status.text = "XP: %d   |   Cost: %d per skill" % [character.xp, purchase_cost]
	else:
		%Status.text = "Meta XP: %d   |   Cost: %d per unlock" % [save_state.meta_xp, purchase_cost]

func _refresh_tab_badges() -> void:
	for pane in _panes:
		var count := 0
		for s in pane.tree.skills:
			if _state(s) == SkillState.BUYABLE:
				count += 1
		var base: String = Skill.TreeType.keys()[pane.tree.tree_type]
		pane.name = "%s (%d)" % [base, count] if count > 0 else base

func hover_skill(skill: Skill) -> void:
	_hovered_skill = skill
	var info := %Info as RichTextLabel
	info.bbcode_enabled = true
	if not skill:
		info.text = "[i]Hover a skill for details.[/i]"
		return
	# Shrouded skills don't get a detail panel — that's the point.
	if _is_shrouded(skill):
		info.text = "[i]Unknown skill. Unlock prerequisites to reveal.[/i]"
		return
	var lines: PackedStringArray = []
	lines.append("[b]%s[/b]" % skill.name())
	lines.append("[color=#bbbbbb]%s[/color]" % skill.type_name())
	lines.append("")
	lines.append("[b]State:[/b] %s" % _state_label(skill))
	if skill.parent:
		var parent_state := "✓" if (_is_acquired(skill.parent) or (mode == Mode.UNLOCK and _is_unlocked(skill.parent))) else "✗"
		lines.append("[b]Requires:[/b] %s (%s)" % [skill.parent.name(), parent_state])
	lines.append("[b]Cost:[/b] %d %s" % [purchase_cost, "XP" if mode == Mode.ACQUIRE else "Meta XP"])
	lines.append("")
	lines.append(skill.description())
	info.text = "\n".join(lines)

# ============================================================================
# State helpers — read by inner classes via the outer ui ref.
# ============================================================================

func _is_acquired(s: Skill) -> bool:
	return acquired_skills != null and acquired_skills.available(s)

func _is_unlocked(s: Skill) -> bool:
	return unlocked_skills != null and unlocked_skills.available(s)

# 0 = self is known; 1 = parent known (or root); 2+ = farther.
func _distance_to_known(s: Skill) -> int:
	if _is_acquired(s) or _is_unlocked(s):
		return 0
	var current: Skill = s.parent
	var d := 1
	while current:
		if _is_acquired(current) or _is_unlocked(current):
			return d
		current = current.parent
		d += 1
	return d

func _is_shrouded(s: Skill) -> bool:
	# Unlocked skills are ALWAYS shown in full, regardless of distance.
	if _is_unlocked(s):
		return false
	return _distance_to_known(s) >= 2

func _state(s: Skill) -> SkillState:
	if mode == Mode.ACQUIRE:
		if _is_acquired(s):
			return SkillState.OWNED
		if not _is_unlocked(s):
			return SkillState.SHROUDED if _is_shrouded(s) else SkillState.LOCKED_ADJACENT
		if s.parent and not _is_acquired(s.parent):
			return SkillState.NEED_PARENT
		if not character.has_xp(purchase_cost):
			return SkillState.NEED_XP
		return SkillState.BUYABLE
	else:  # UNLOCK
		if _is_unlocked(s):
			return SkillState.OWNED
		if s.parent and not _is_unlocked(s.parent):
			return SkillState.NEED_PARENT
		if save_state.meta_xp < purchase_cost:
			return SkillState.NEED_XP
		return SkillState.BUYABLE

func _state_label(s: Skill) -> String:
	match _state(s):
		SkillState.OWNED:
			return "Owned" if mode == Mode.ACQUIRE else "Unlocked"
		SkillState.BUYABLE:
			return "Available"
		SkillState.NEED_XP:
			return "Need XP"
		SkillState.NEED_PARENT:
			return "Need: %s" % (s.parent.name() if s.parent else "?")
		SkillState.LOCKED_ADJACENT:
			return "Locked"
		SkillState.SHROUDED:
			return "???"
	return "?"

func _state_color(s: Skill) -> Color:
	return STATE_COLORS.get(_state(s), Color.WHITE)

func _type_border_color(s: Skill) -> Color:
	var profile = SkillStyles.profile_for_skill_type(s.skill_type)
	if profile:
		return profile.color_theme
	return Color(0.4, 0.4, 0.4, 1.0)

# ============================================================================
# Purchase
# ============================================================================

func buy_skill(s: Skill) -> void:
	if mode == Mode.ACQUIRE:
		assert(character.has_xp(purchase_cost))
		character.use_xp(purchase_cost)
		acquired_skills.mark_available(s)
	else:
		assert(save_state.meta_xp >= purchase_cost)
		save_state.meta_xp -= purchase_cost
		unlocked_skills.mark_available(s)
	_refresh()
	# Re-hover the same skill so the sidebar reflects the new state.
	if _hovered_skill:
		hover_skill(_hovered_skill)

func _on_ok_pressed() -> void:
	ok_pressed.emit()

# ============================================================================
# TreePane — one tab; hosts a scrollable TreeCanvas.
# ============================================================================
class TreePane extends ScrollContainer:
	var ui: SkillTreeUI
	var tree: SkillTree
	var canvas: TreeCanvas

	func _init(ui_: SkillTreeUI, tree_: SkillTree):
		ui = ui_
		tree = tree_
		horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		canvas = TreeCanvas.new(ui, tree)
		add_child(canvas)

	func refresh() -> void:
		canvas.refresh()

# ============================================================================
# TreeCanvas — places SkillCards in a column-by-depth layout and draws edges.
# ============================================================================
class TreeCanvas extends Control:
	var ui: SkillTreeUI
	var tree: SkillTree
	var cards: Dictionary = {}      # Skill -> SkillCard
	var positions: Dictionary = {}  # Skill -> Vector2 (top-left of card)

	func _init(ui_: SkillTreeUI, tree_: SkillTree):
		ui = ui_
		tree = tree_
		_build()

	func _build() -> void:
		# Depth memo (column index per skill).
		var depth: Dictionary = {}
		for s in tree.skills:
			_compute_depth(s, depth)
		# Child index: parent -> sorted list of children (in our tree).
		var children: Dictionary = {}
		for s in tree.skills:
			if not children.has(s):
				children[s] = []
			if s.parent and tree.skills.has(s.parent):
				if not children.has(s.parent):
					children[s.parent] = []
				children[s.parent].append(s)
		for k in children.keys():
			(children[k] as Array).sort_custom(func(a, b): return String(a.name()) < String(b.name()))
		# Roots in this tree (no parent OR parent not in this tree).
		var roots: Array[Skill] = []
		for s in tree.skills:
			if s.parent == null or not tree.skills.has(s.parent):
				roots.append(s)
		roots.sort_custom(func(a, b): return String(a.name()) < String(b.name()))
		# Assign rows depth-first so each subtree's rows are contiguous and
		# parents end up vertically centered over their children. Keeps
		# edges short and avoids crossings on single-parent trees.
		var row_of: Dictionary = {}
		var next_row := 0
		for r in roots:
			next_row = _assign_rows(r, children, row_of, next_row)
		# Place cards.
		var max_col := 0
		var max_row := 0
		for s in tree.skills:
			var col: int = depth[s]
			var row: int = row_of[s]
			max_col = max(max_col, col)
			max_row = max(max_row, row)
			var pos := Vector2(
				SkillTreeUI.TREE_PADDING + col * SkillTreeUI.COLUMN_W,
				SkillTreeUI.TREE_PADDING + row * SkillTreeUI.ROW_H,
			)
			positions[s] = pos
			var card := SkillCard.new(ui, s)
			card.position = pos
			card.size = Vector2(SkillTreeUI.CARD_WIDTH, SkillTreeUI.CARD_HEIGHT)
			add_child(card)
			cards[s] = card
		custom_minimum_size = Vector2(
			(max_col + 1) * SkillTreeUI.COLUMN_W + SkillTreeUI.TREE_PADDING * 2,
			(max_row + 1) * SkillTreeUI.ROW_H + SkillTreeUI.TREE_PADDING * 2,
		)

	# Returns the next free row after the subtree rooted at `s` is placed.
	# Children get rows in order starting at `start_row`; the parent is
	# placed at the midpoint of its first and last child (or at start_row
	# if leaf).
	func _assign_rows(s: Skill, children: Dictionary, row_of: Dictionary, start_row: int) -> int:
		var kids: Array = children.get(s, [])
		if kids.is_empty():
			row_of[s] = start_row
			return start_row + 1
		var first_child_row := start_row
		var cursor := start_row
		for c in kids:
			cursor = _assign_rows(c, children, row_of, cursor)
		var last_child_row := cursor - 1
		row_of[s] = (first_child_row + last_child_row) / 2
		return cursor

	func _compute_depth(s: Skill, memo: Dictionary) -> int:
		if memo.has(s):
			return memo[s]
		var d := 0
		if s.parent and tree.skills.has(s.parent):
			d = _compute_depth(s.parent, memo) + 1
		memo[s] = d
		return d

	func refresh() -> void:
		for s in cards:
			(cards[s] as SkillCard).refresh()
		queue_redraw()

	func _draw() -> void:
		for s in cards:
			if not s.parent or not cards.has(s.parent):
				continue
			# Both parent and child shrouded → don't draw the edge at all
			# (the parent silhouette already implies "something further out").
			if ui._is_shrouded(s) and ui._is_shrouded(s.parent):
				continue
			var from: Vector2 = positions[s.parent] + Vector2(SkillTreeUI.CARD_WIDTH, SkillTreeUI.CARD_HEIGHT / 2.0)
			var to: Vector2 = positions[s] + Vector2(0, SkillTreeUI.CARD_HEIGHT / 2.0)
			# Edge color reflects the child's state — "this is what you'd be moving toward."
			var col: Color = ui._state_color(s)
			draw_line(from, to, col, 2.0, true)

# ============================================================================
# SkillCard — one card in the tree.
# ============================================================================
class SkillCard extends PanelContainer:
	var ui: SkillTreeUI
	var skill: Skill
	var _name_chip: PanelContainer
	var _name_label: Label
	var _status_label: Label
	var _cost_label: Label
	var _buy_button: Button
	var _shroud_label: Label
	var _content_vb: VBoxContainer

	func _init(ui_: SkillTreeUI, skill_: Skill):
		ui = ui_
		skill = skill_
		custom_minimum_size = Vector2(SkillTreeUI.CARD_WIDTH, SkillTreeUI.CARD_HEIGHT)
		# Pin the size — we lay these out absolutely and don't want
		# child content to push the panel taller than CARD_HEIGHT.
		size = Vector2(SkillTreeUI.CARD_WIDTH, SkillTreeUI.CARD_HEIGHT)
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_entered.connect(_on_hover_in)
		mouse_exited.connect(_on_hover_out)
		var margin := MarginContainer.new()
		margin.anchor_right = 1.0
		margin.anchor_bottom = 1.0
		margin.add_theme_constant_override("margin_left", 6)
		margin.add_theme_constant_override("margin_right", 6)
		margin.add_theme_constant_override("margin_top", 3)
		margin.add_theme_constant_override("margin_bottom", 3)
		add_child(margin)
		_content_vb = VBoxContainer.new()
		_content_vb.add_theme_constant_override("separation", 1)
		margin.add_child(_content_vb)
		
		# Name chip container for type-specific styling
		_name_chip = PanelContainer.new()
		_content_vb.add_child(_name_chip)
		
		_name_label = Label.new()
		_name_label.add_theme_font_size_override("font_size", 10)
		_name_label.clip_text = true
		_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_name_chip.add_child(_name_label)
		
		# Bottom row: status text on the left, buy button on the right.
		# When not buyable the button is hidden and the status takes the
		# whole row.
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 4)
		hb.size_flags_vertical = SIZE_EXPAND_FILL
		_content_vb.add_child(hb)
		_status_label = Label.new()
		_status_label.add_theme_font_size_override("font_size", 10)
		_status_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		_status_label.size_flags_horizontal = SIZE_EXPAND_FILL
		_status_label.size_flags_vertical = SIZE_SHRINK_CENTER
		_status_label.clip_text = true
		hb.add_child(_status_label)
		_buy_button = Button.new()
		_buy_button.add_theme_font_size_override("font_size", 10)
		_buy_button.custom_minimum_size = Vector2(60, 20)
		_buy_button.size_flags_vertical = SIZE_SHRINK_CENTER
		_buy_button.pressed.connect(_on_buy_pressed)
		hb.add_child(_buy_button)
		# We don't keep a separate _cost_label — the cost lives inside the
		# buy button text ("Buy 150").
		_cost_label = null
		# Shroud overlay — replaces content when SHROUDED.
		_shroud_label = Label.new()
		_shroud_label.text = "?"
		_shroud_label.add_theme_font_size_override("font_size", 24)
		_shroud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_shroud_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_shroud_label.anchor_right = 1.0
		_shroud_label.anchor_bottom = 1.0
		_shroud_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5, 1.0))
		_shroud_label.visible = false
		add_child(_shroud_label)
		refresh()

	func refresh() -> void:
		var state: int = ui._state(skill)
		var bg: Color = ui._state_color(skill)
		var border: Color = ui._type_border_color(skill)
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		sb.set_border_width_all(2)
		sb.border_color = border
		sb.set_corner_radius_all(5)
		sb.set_content_margin_all(0)
		add_theme_stylebox_override("panel", sb)
		if state == SkillTreeUI.SkillState.SHROUDED:
			_content_vb.visible = false
			_shroud_label.visible = true
			return
		_content_vb.visible = true
		_shroud_label.visible = false
		_name_label.text = String(skill.name())
		_status_label.text = ui._state_label(skill)
		_buy_button.text = "Buy %d" % ui.purchase_cost
		_buy_button.visible = (state == SkillTreeUI.SkillState.BUYABLE)
		
		# Style the name chip dynamically based on type
		var profile = SkillStyles.profile_for_skill_type(skill.skill_type)
		var chip_style := StyleBoxFlat.new()
		
		chip_style.corner_radius_top_left = profile.corner_radius_top_left
		chip_style.corner_radius_top_right = profile.corner_radius_top_right
		chip_style.corner_radius_bottom_right = profile.corner_radius_bottom_right
		chip_style.corner_radius_bottom_left = profile.corner_radius_bottom_left
		
		var theme_color = profile.color_theme
		chip_style.bg_color = Color(theme_color.r, theme_color.g, theme_color.b, 0.15)
		chip_style.border_color = Color(theme_color.r, theme_color.g, theme_color.b, 0.4)
		chip_style.set_border_width_all(1)
		chip_style.set_content_margin_individual(6, 2, 6, 2)
		_name_chip.add_theme_stylebox_override("panel", chip_style)
		_name_label.add_theme_color_override("font_color", profile.text_color_filled())

	func _on_hover_in() -> void:
		ui.hover_skill(skill)

	func _on_hover_out() -> void:
		# Don't clear — leave the last hovered detail up. Picked back up
		# on the next hover_in.
		pass

	func _on_buy_pressed() -> void:
		ui.buy_skill(skill)
