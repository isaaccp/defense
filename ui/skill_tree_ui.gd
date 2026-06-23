extends Control

class_name SkillTreeUI

const skill_tree_collection = preload("res://skill_tree/trees/skill_tree_collection.tres")

# Card / layout sizing — referenced from inner classes via SkillTreeUI.*.
const CARD_WIDTH := 240.0
const CARD_HEIGHT := 80.0
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
}

const STATE_COLORS := {
	SkillState.OWNED: Color(0.32, 0.32, 0.34, 1.0),
	SkillState.BUYABLE: Color(0.30, 0.65, 0.30, 1.0),
	SkillState.NEED_XP: Color(0.75, 0.62, 0.18, 1.0),
	SkillState.NEED_PARENT: Color(0.28, 0.46, 0.72, 1.0),
	SkillState.LOCKED_ADJACENT: Color(0.50, 0.30, 0.62, 1.0),
}



enum Mode { ACQUIRE, VIEW_META }

var mode: Mode
var save_state: SaveState
var level_provider: LevelProvider
var character: GameplayCharacter
var unlocked_skills: SkillTreeState
var acquired_skills: SkillTreeState

# Until we vary cost by skill, one flat number for everything.
var purchase_cost: int = 150
var hide_locked_skills: bool = false

var _panes: Array = []
var _hovered_skill: Skill

signal ok_pressed

@export_group("Testing")
@export var test_mode: Mode
@export var test_character: GameplayCharacter

func _ready() -> void:
	if get_parent() == get_tree().root:
		_ready_standalone()
		return
	_build_tabs()

func _ready_standalone() -> void:
	var ss := SaveState.make_new()
	ss.unlocked_skills = SkillTreeState.new()
	if test_mode == Mode.VIEW_META:
		ss.unlocked_skills.mark_available(preload("res://skill_tree/meta_skills/behavior_library.tres"))
		ss.unlocked_skills.mark_available(preload("res://skill_tree/meta_skills/gold_chests.tres"))
		# Add mock data for regular trees so they aren't empty in standalone mode
		ss.unlocked_skills.mark_available(preload("res://skill_tree/actions/sword_attack.tres"))
		ss.unlocked_skills.mark_available(preload("res://skill_tree/actions/charge.tres"))
		ss.unlocked_skills.mark_available(preload("res://skill_tree/actions/cleave.tres"))
		ss.unlocked_skills.mark_available(preload("res://skill_tree/actions/sweeping_attack.tres"))
		var lp = LevelProvider.new()
		if test_character:
			if test_character.available_skill_trees == null or test_character.available_skill_trees.is_empty():
				var test_arr: Array[Skill.TreeType] = [Skill.TreeType.WARRIOR, Skill.TreeType.ROGUE]
				test_character.available_skill_trees = test_arr
			var chars: Array[GameplayCharacter] = [test_character]
			lp.available_characters = chars
		initialize(test_mode, ss, lp, null, true)
	elif test_mode == Mode.ACQUIRE:
		ss.unlocked_skills.full = true
		assert(test_character)
		var rs = RunSaveState.new()
		if test_character.available_skill_trees == null or test_character.available_skill_trees.is_empty():
			var test_arr: Array[Skill.TreeType] = [Skill.TreeType.WARRIOR, Skill.TreeType.ROGUE]
			test_character.available_skill_trees = test_arr
		var chars: Array[GameplayCharacter] = [test_character]
		rs.gameplay_characters = chars
		ss.run_save_state = rs
		initialize(test_mode, ss, null, test_character)

func initialize(mode_: Mode, save_state_: SaveState, level_provider_: LevelProvider = null, character_: GameplayCharacter = null, show_all: bool = false) -> void:
	assert(save_state_)
	if mode_ == Mode.ACQUIRE:
		assert(character_)
	mode = mode_
	save_state = save_state_
	level_provider = level_provider_
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
	%Title.text = "Skill Tree" if mode == Mode.ACQUIRE else "View Meta Progression"
	
	var visible_trees = { Skill.TreeType.GENERAL: true }
	if mode == Mode.VIEW_META:
		visible_trees[Skill.TreeType.META] = true
		if level_provider:
			for c in level_provider.available_characters:
				if c.is_unlocked(save_state.unlocked_skills):
					for t in c.available_skill_trees:
						visible_trees[t] = true
	elif mode == Mode.ACQUIRE:
		if character and character.available_skill_trees != null:
			for t in character.available_skill_trees:
				visible_trees[t] = true
					
	for t in skill_tree_collection.skill_trees:
		if not visible_trees.has(t.tree_type):
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
	if mode == Mode.VIEW_META:
		%Status.text = "Skills Unlocked: %d / %d" % [save_state.unlocked_skills.skills.size(), SkillManager.all_skills.size()]
	elif character:
		%Status.text = "Run XP: %d   |   Cost: %d per pick" % [character.xp, purchase_cost]

func _refresh_tab_badges() -> void:
	var tabs := %Trees as TabContainer
	for pane in _panes:
		var count := 0
		for s in pane.tree.skills:
			if _state(s) == SkillState.BUYABLE:
				count += 1
		var base: String = Skill.TreeType.keys()[pane.tree.tree_type]
		var title: String
		if mode == Mode.VIEW_META:
			title = base
		else:
			title = "%s (%d)" % [base, count] if count > 0 else base
		tabs.set_tab_title(pane.get_index(), title)
func hover_skill(skill: Skill) -> void:
	_hovered_skill = skill
	var info := %Info as RichTextLabel
	info.bbcode_enabled = true
	if not skill:
		info.text = "[i]Hover a skill for details.[/i]"
		return
	var lines: PackedStringArray = []
	lines.append("[b]%s[/b]" % skill.name())
	lines.append("[color=#bbbbbb]%s[/color]" % skill.type_name())
	lines.append("")
	if mode == Mode.ACQUIRE:
		lines.append("[b]State:[/b] %s" % _state_label(skill))
		if skill.parent:
			var parent_state := "✓" if _is_acquired(skill.parent) else "✗"
			lines.append("[b]Requires:[/b] %s (%s)" % [skill.parent.name(), parent_state])
		lines.append("[b]Cost:[/b] %d %s" % [purchase_cost, "XP"])
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

func _state(s: Skill) -> SkillState:
	if mode == Mode.ACQUIRE:
		if _is_acquired(s):
			return SkillState.OWNED
		if not _is_unlocked(s):
			return SkillState.LOCKED_ADJACENT
		if s.parent and not _is_acquired(s.parent):
			return SkillState.NEED_PARENT
		if not character.has_xp(purchase_cost):
			return SkillState.NEED_XP
		return SkillState.BUYABLE
	else:  # VIEW_META
		if _is_unlocked(s):
			return SkillState.OWNED
		return SkillState.LOCKED_ADJACENT

func _state_label(s: Skill) -> String:
	match _state(s):
		SkillState.OWNED:
			if mode == Mode.ACQUIRE and s.tree_type == Skill.TreeType.GENERAL:
				return "Auto-Acquired"
			return "Owned" if mode == Mode.ACQUIRE else "Unlocked"
		SkillState.BUYABLE:
			return "Available"
		SkillState.NEED_XP:
			return "Need XP"
		SkillState.NEED_PARENT:
			return "Need: %s" % (s.parent.name() if s.parent else "?")
		SkillState.LOCKED_ADJACENT:
			return "Locked"
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
	var canvas: Control

	func _init(ui_: SkillTreeUI, tree_: SkillTree):
		ui = ui_
		tree = tree_
		horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		if tree.tree_type == Skill.TreeType.META:
			var margin = MarginContainer.new()
			margin.add_theme_constant_override("margin_left", 20)
			margin.add_theme_constant_override("margin_top", 20)
			margin.add_theme_constant_override("margin_right", 20)
			margin.add_theme_constant_override("margin_bottom", 20)
			margin.size_flags_horizontal = SIZE_EXPAND_FILL
			add_child(margin)
			canvas = MetaCanvas.new(ui, tree)
			margin.add_child(canvas)
		else:
			var wrapper = VBoxContainer.new()
			wrapper.size_flags_horizontal = SIZE_EXPAND_FILL
			wrapper.size_flags_vertical = SIZE_EXPAND_FILL
			add_child(wrapper)
			if tree.tree_type == Skill.TreeType.GENERAL and ui.mode == Mode.ACQUIRE:
				var margin = MarginContainer.new()
				margin.add_theme_constant_override("margin_left", 20)
				margin.add_theme_constant_override("margin_top", 10)
				margin.add_theme_constant_override("margin_bottom", 10)
				var lbl = Label.new()
				lbl.text = "General skills are automatically acquired when unlocked globally, and cost 0 XP."
				lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
				lbl.add_theme_font_size_override("font_size", 18)
				margin.add_child(lbl)
				wrapper.add_child(margin)
			canvas = TreeCanvas.new(ui, tree)
			wrapper.add_child(canvas)

	func refresh() -> void:
		canvas.refresh()

# ============================================================================
# MetaCanvas — flat layout for meta skills (HFlowContainer).
# ============================================================================
class MetaCanvas extends HFlowContainer:
	var ui: SkillTreeUI
	var tree: SkillTree
	var cards: Dictionary = {}

	func _init(ui_: SkillTreeUI, tree_: SkillTree):
		ui = ui_
		tree = tree_
		size_flags_horizontal = SIZE_EXPAND_FILL
		add_theme_constant_override("h_separation", 20)
		add_theme_constant_override("v_separation", 20)
		_build()

	func _build() -> void:
		for s in tree.skills:
			if ui.hide_locked_skills and not ui._is_unlocked(s):
				continue
			var card = SkillCard.new(ui, s)
			add_child(card)
			cards[s] = card

	func refresh() -> void:
		for s in cards:
			(cards[s] as SkillCard).refresh()

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
		var skills_to_render = []
		for s in tree.skills:
			if ui.hide_locked_skills and not ui._is_unlocked(s):
				continue
			skills_to_render.append(s)

		# Depth memo (column index per skill).
		var depth: Dictionary = {}
		for s in skills_to_render:
			_compute_depth(s, depth, skills_to_render)
		# Child index: parent -> sorted list of children (in our tree).
		var children: Dictionary = {}
		for s in skills_to_render:
			if not children.has(s):
				children[s] = []
			if s.parent and skills_to_render.has(s.parent):
				if not children.has(s.parent):
					children[s.parent] = []
				children[s.parent].append(s)
		for k in children.keys():
			(children[k] as Array).sort_custom(func(a, b): return String(a.name()) < String(b.name()))
		# Roots in this tree (no parent OR parent not in this tree).
		var roots: Array[Skill] = []
		for s in skills_to_render:
			if s.parent == null or not skills_to_render.has(s.parent):
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
		for s in skills_to_render:
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

	func _compute_depth(s: Skill, memo: Dictionary, skills_to_render: Array) -> int:
		if memo.has(s):
			return memo[s]
		var d := 0
		if s.parent and skills_to_render.has(s.parent):
			d = _compute_depth(s.parent, memo, skills_to_render) + 1
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
	var _buy_button: Button
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
		_name_label.add_theme_font_size_override("font_size", 18)
		_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		_name_label.add_theme_constant_override("shadow_offset_x", 1)
		_name_label.add_theme_constant_override("shadow_offset_y", 2)
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
		_status_label.add_theme_font_size_override("font_size", 16)
		_status_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		_status_label.size_flags_horizontal = SIZE_EXPAND_FILL
		_status_label.size_flags_vertical = SIZE_SHRINK_CENTER
		_status_label.clip_text = true
		hb.add_child(_status_label)
		_buy_button = Button.new()
		_buy_button.add_theme_font_size_override("font_size", 16)
		_buy_button.custom_minimum_size = Vector2(90, 28)
		_buy_button.size_flags_vertical = SIZE_SHRINK_CENTER
		_buy_button.pressed.connect(_on_buy_pressed)
		hb.add_child(_buy_button)
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

		# Tooltip / sidebar description
		var req_skills = skill.required_skills()
		var tip = ""
		if not req_skills.is_empty() and skill.tree_type != Skill.TreeType.META:
			tip += "[Requires: %s]\n\n" % ", ".join(req_skills)
		tip += skill.description()
		self.tooltip_text = tip

		_content_vb.visible = true
		_name_label.text = skill.name()
		if ui.mode == Mode.VIEW_META:
			_status_label.text = ""
		else:
			_status_label.text = ui._state_label(skill)
		_buy_button.text = "Buy %d" % ui.purchase_cost
		# Buy button only shows up if the state is BUYABLE.
		# In VIEW_META, we don't buy skills.
		_buy_button.visible = (state == SkillTreeUI.SkillState.BUYABLE and ui.mode != SkillTreeUI.Mode.VIEW_META)
		
		# Style the name chip dynamically based on type
		var profile = SkillStyles.profile_for_skill_type(skill.skill_type)
		var chip_style := StyleBoxFlat.new()
		
		chip_style.corner_radius_top_left = profile.corner_radius_top_left
		chip_style.corner_radius_top_right = profile.corner_radius_top_right
		chip_style.corner_radius_bottom_right = profile.corner_radius_bottom_right
		chip_style.corner_radius_bottom_left = profile.corner_radius_bottom_left
		
		var theme_color = profile.color_theme
		chip_style.bg_color = Color(theme_color.r * 0.2, theme_color.g * 0.2, theme_color.b * 0.2, 0.8)
		chip_style.border_color = Color(theme_color.r, theme_color.g, theme_color.b, 0.8)
		chip_style.set_border_width_all(1)
		chip_style.content_margin_left = 6
		chip_style.content_margin_top = 2
		chip_style.content_margin_right = 6
		chip_style.content_margin_bottom = 2
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
