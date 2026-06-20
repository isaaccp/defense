@tool
extends Control
class_name MapVisual

@export var path_0_slots: Array[Marker2D] = []
@export var path_1_slots: Array[Marker2D] = []
@export var next_stage_slot: Marker2D

@onready var path_0_visuals: Node2D = get_node_or_null("Path0_Visuals")
@onready var path_1_visuals: Node2D = get_node_or_null("Path1_Visuals")

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_ensure_structure()

func _draw() -> void:
	if Engine.is_editor_hint():
		var tex = preload("res://assets/kenney-cartography/Textures/parchmentFoldedCrinkled.png")
		# MapScreen container size is 1650x842. This draws the boundary centered at 0,0
		var rect = Rect2(Vector2(-1650/2.0, -842/2.0), Vector2(1650, 842))
		draw_texture_rect(tex, rect, false, Color(1.0, 1.0, 1.0, 0.6))
		# Draw a faint red border to show the absolute max bounds
		draw_rect(rect, Color(1, 0, 0, 0.4), false, 4.0)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_path_to_line(path_0_visuals)
		_sync_path_to_line(path_1_visuals)

func _sync_path_to_line(visuals_node: Node2D) -> void:
	if not visuals_node: return
	var path2d: Path2D = visuals_node.get_node_or_null("PathLine")
	if not path2d: return
	var line2d: Line2D = path2d.get_node_or_null("PathLineDraw")
	if line2d and path2d.curve:
		line2d.points = path2d.curve.tessellate()

func _ensure_structure() -> void:
	if not get_node_or_null("Decorations"):
		var dec = Node2D.new()
		dec.name = "Decorations"
		add_child(dec)
		dec.owner = self if not owner else owner
		
	if not get_node_or_null("Path0_Visuals"):
		_build_path_skeleton("Path0_Visuals", Vector2(-300, 0))
		
	if not get_node_or_null("Path1_Visuals"):
		_build_path_skeleton("Path1_Visuals", Vector2(300, 0))
		
	if not get_node_or_null("NextStage_Slot"):
		var bs = Marker2D.new()
		bs.name = "NextStage_Slot"
		add_child(bs)
		bs.position = Vector2(0, -300)
		bs.owner = self if not owner else owner

func _build_path_skeleton(pname: String, curve_offset: Vector2) -> void:
	var p = Node2D.new()
	p.name = pname
	add_child(p)
	p.owner = self if not owner else owner
	
	var path2d = Path2D.new()
	path2d.name = "PathLine"
	var curve = Curve2D.new()
	curve.add_point(Vector2(0, 250))
	curve.add_point(Vector2(0, 250) + curve_offset)
	curve.add_point(Vector2(0, -250))
	path2d.curve = curve
	p.add_child(path2d)
	path2d.owner = p.owner
	
	var line2d = Line2D.new()
	line2d.name = "PathLineDraw"
	line2d.width = 4.0
	line2d.texture_mode = Line2D.LINE_TEXTURE_TILE
	line2d.material = preload("res://effects/shaders/dashed_line.gdshader")
	path2d.add_child(line2d)
	line2d.owner = p.owner
	
	var slots = Node2D.new()
	slots.name = "RewardSlots"
	p.add_child(slots)
	slots.owner = p.owner
	
	var curve_len = curve.get_baked_length()
	for i in range(3):
		var slot = Marker2D.new()
		slot.name = "Slot%d" % i
		# Space them out evenly (e.g. 25%, 50%, 75%)
		slot.position = curve.sample_baked(curve_len * ((i + 1) / 4.0))
		slots.add_child(slot)
		slot.owner = p.owner

func set_path_dimmed(path_idx: int, dimmed: bool) -> void:
	var target = path_0_visuals if path_idx == 0 else path_1_visuals
	if not target: return
	
	if dimmed:
		target.modulate = Color(0.4, 0.4, 0.4, 0.7)
	else:
		target.modulate = Color.WHITE

func reset_dimming() -> void:
	if path_0_visuals: path_0_visuals.modulate = Color.WHITE
	if path_1_visuals: path_1_visuals.modulate = Color.WHITE

func set_path_highlighted(path_idx: int, highlighted: bool) -> void:
	var target = path_0_visuals if path_idx == 0 else path_1_visuals
	if not target: return
	
	var path: Path2D = target.get_node_or_null("PathLine")
	if not path: return
	var line: Line2D = path.get_node_or_null("PathLineDraw")
	if line:
		if highlighted:
			line.width = 8.0
			line.set_instance_shader_parameter("line_color", Color(1.0, 0.9, 0.2, 1.0))
			line.set_instance_shader_parameter("speed", -25.0)
		else:
			line.width = 4.0
			line.set_instance_shader_parameter("line_color", Color(0.3, 0.2, 0.1, 0.6))
			line.set_instance_shader_parameter("speed", 0.0)

func reset_path_highlights() -> void:
	set_path_highlighted(0, false)
	set_path_highlighted(1, false)
