@tool
extends Node2D

class_name DecorationScatter

# Scatters instances of a decoration scene at random positions inside an area.
# Useful for stage design: a single scatter node replaces 20-50 hand-placed
# decoration positions in a .tscn.
#
# Children are spawned without an owner so they don't get serialized into the
# scene file — only the scatter node and its config are saved; children
# regenerate at every _ready. In the editor, scatter re-runs automatically
# whenever any export changes (so you see live previews of count/area/etc.).
# The "Regenerate" inspector button rolls a fresh random seed and writes it
# to rng_seed — click until you like the layout, then save the scene.

@export var decoration: PackedScene: set = _set_decoration
@export var count: int = 10: set = _set_count
# Shape to scatter within. Use RectScatterArea, CircleScatterArea, or
# AnnulusScatterArea (or write your own).
@export var area: ScatterArea: set = _set_area
# 0 = fresh random seed each scatter; nonzero = deterministic.
@export var rng_seed: int = 0: set = _set_rng_seed
# Minimum distance between placed decorations. 0 = no constraint.
@export var min_distance: float = 0.0: set = _set_min_distance
@export_tool_button("Regenerate (new seed)") var _regen_button = _regenerate_with_new_seed

func _ready() -> void:
	scatter()

func scatter() -> void:
	_clear()
	if not decoration or not area:
		return
	var rng := RandomNumberGenerator.new()
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	var placed: Array[Vector2] = []
	var max_attempts := count * 20
	var attempts := 0
	while placed.size() < count and attempts < max_attempts:
		attempts += 1
		var p := area.random_point(rng)
		if min_distance > 0.0:
			var too_close := false
			for q in placed:
				if p.distance_to(q) < min_distance:
					too_close = true
					break
			if too_close:
				continue
		placed.append(p)
		var instance: Node2D = decoration.instantiate()
		instance.position = p
		add_child(instance)

func _clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _regenerate_with_new_seed() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# Avoid 0 — at runtime 0 means "fresh random each load".
	rng_seed = rng.randi_range(1, 2147483647)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not decoration:
		warnings.append("decoration is not set — nothing will be scattered.")
	if not area:
		warnings.append("area is not set — assign a RectScatterArea, CircleScatterArea, or AnnulusScatterArea.")
	return warnings

func _set_decoration(v: PackedScene) -> void:
	decoration = v
	_on_property_changed()

func _set_count(v: int) -> void:
	count = v
	_on_property_changed()

func _set_area(v: ScatterArea) -> void:
	area = v
	_on_property_changed()

func _set_rng_seed(v: int) -> void:
	rng_seed = v
	_on_property_changed()

func _set_min_distance(v: float) -> void:
	min_distance = v
	_on_property_changed()

func _on_property_changed() -> void:
	update_configuration_warnings()
	if is_inside_tree():
		scatter()
	queue_redraw()

func _draw() -> void:
	if Engine.is_editor_hint() and area:
		area.draw_boundary(self)
