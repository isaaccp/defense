extends Control
class_name RewardNode

enum State { PRECHOICE, PENDING, IN_PROGRESS, DONE, GREYED }

signal clicked(node: RewardNode)
signal hovered(node: RewardNode)
signal unhovered(node: RewardNode)

@export var reward: RewardDef
var state: int = State.PRECHOICE
var is_next_stage: bool = false

@onready var icon: TextureRect = $Icon
@onready var button: TextureButton = $Button
@onready var tooltip_panel: PanelContainer = $TooltipPanel
@onready var tooltip_label: Label = $TooltipPanel/MarginContainer/TooltipLabel

func _ready() -> void:
	button.pressed.connect(func(): clicked.emit(self))
	button.mouse_entered.connect(func(): hovered.emit(self))
	button.mouse_exited.connect(func(): unhovered.emit(self))
	_update_visuals()

func setup(r: RewardDef, next_stage: bool = false) -> void:
	reward = r
	is_next_stage = next_stage
	
	if is_next_stage:
		icon.texture = preload("res://assets/kenney-cartography/PNG/compass.png")
		tooltip_label.text = "[Next Battle]"
	elif reward != null:
		var script_path = reward.get_script().resource_path
		if "relic" in script_path:
			icon.texture = preload("res://assets/kenney-cartography/PNG/chest.png")
		elif "rest" in script_path:
			icon.texture = preload("res://assets/kenney-cartography/PNG/campfire.png")
		elif "trainer" in script_path:
			icon.texture = preload("res://assets/kenney-cartography/PNG/tent.png")
		else:
			icon.texture = preload("res://assets/kenney-cartography/PNG/flag.png")
			
		tooltip_label.text = "[color=gold]%s[/color]\n%s" % [reward.display_name, reward.description]
	
	_update_visuals()

func set_floating_tooltip_visible(v: bool) -> void:
	if tooltip_panel:
		tooltip_panel.visible = v
		if v and reward:
			# Parse BBCode manually or use RichTextLabel if we want colors. 
			# Actually wait, Label doesn't support BBCode. Let me strip the [color] tag or just use plain text.
			tooltip_label.text = reward.display_name + "\n" + reward.description
		elif v and is_next_stage:
			tooltip_label.text = "[Next Battle]"

func set_state(s: int) -> void:
	state = s
	_update_visuals()

func set_highlighted(h: bool) -> void:
	if icon:
		icon.set_instance_shader_parameter("highlight_intensity", 1.0 if h else 0.0)

func _update_visuals() -> void:
	if not is_inside_tree(): return
	
	match state:
		State.PRECHOICE:
			modulate = Color.WHITE
			icon.modulate = Color(1, 1, 1, 1)
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		State.PENDING:
			modulate = Color.WHITE
			icon.modulate = Color(1.2, 1.2, 1.2, 1)
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			button.mouse_filter = Control.MOUSE_FILTER_STOP
		State.IN_PROGRESS:
			modulate = Color.WHITE
			icon.modulate = Color(1.5, 1.5, 0.5, 1)
			button.mouse_default_cursor_shape = Control.CURSOR_ARROW
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		State.DONE:
			modulate = Color(0.4, 0.4, 0.4, 1)
			icon.modulate = Color(1, 1, 1, 0.5)
			button.mouse_default_cursor_shape = Control.CURSOR_ARROW
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		State.GREYED:
			modulate = Color(0.3, 0.3, 0.3, 0.8)
			icon.modulate = Color(1, 1, 1, 0.5)
			button.mouse_default_cursor_shape = Control.CURSOR_ARROW
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
