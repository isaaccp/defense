@tool
extends Node2D

class_name DecorationScatter

# Scatters instances of decoration scenes at random positions inside an area.
#
# A DecorationScatter normally lives under a Zone node and inherits the zone's
# kind (and its area, unless this scatter sets its own sub-area). One zone may
# hold several scatters — e.g. a tree-wall zone with separate tree / obstacle /
# flower passes. A scatter with no parent Zone falls back to its own `kind`
# and `area` exports (standalone use).
#
# Children are spawned without an owner so they don't get serialized into the
# scene file — only the scatter node and its config are saved; children
# regenerate at every _ready. The "Regenerate" inspector button rolls a fresh
# random seed and writes it to rng_seed.
#
# Kind effect: an OPEN zone is walkable gameplay space, so random scatter must
# not drop colliding props there — they are filtered out. ENCLOSED zones allow
# colliding props. Deliberate obstacles in open space are placed as explicit
# structures, not scattered.
#
# Companions: optional small props clustered around each placed decoration
# (e.g. mushrooms at tree bases) — thematic pairing instead of uniform noise.

# Single decoration to scatter. Kept for back-compat. If `decorations` is
# non-empty, that array is used instead.
@export var decoration: PackedScene: set = _set_decoration
# Multiple decoration variants picked from uniformly at random.
@export var decorations: Array[PackedScene] = []: set = _set_decorations
@export var count: int = 10: set = _set_count
# Sub-area to scatter within. If unset, the parent Zone's area is used.
@export var area: ScatterArea: set = _set_area
# 0 = fresh random seed each scatter; nonzero = deterministic.
@export var rng_seed: int = 0: set = _set_rng_seed
# Placement uses Poisson-disk sampling: random points, each rejected if closer
# than `spacing × natural-spacing` to an already-placed point. 0 = pure random
# (clumps allowed); higher = more even (no clumps, no rows). Unlike a grid this
# has no row/column structure. The minimum gap relaxes automatically if `count`
# can't otherwise fit.
@export_range(0.0, 1.0) var spacing: float = 0.65: set = _set_spacing
# Fallback kind when this scatter has no parent Zone (standalone use).
@export var kind: Zone.Kind = Zone.Kind.ENCLOSED: set = _set_kind

@export_group("Companions")
# Small props clustered around each placed decoration (e.g. mushrooms at tree
# bases). Empty = no companions.
@export var companions: Array[PackedScene] = []: set = _set_companions
# Fraction of placed decorations that get a companion cluster.
@export_range(0.0, 1.0) var companion_chance: float = 0.0: set = _set_companion_chance
# Companions per cluster: random count in [x, y].
@export var companion_count: Vector2i = Vector2i(1, 3): set = _set_companion_count
# Max distance a companion is placed from its decoration.
@export var companion_radius: float = 40.0: set = _set_companion_radius

@export_tool_button("Regenerate (new seed)") var _regen_button = _regenerate_with_new_seed

func _ready() -> void:
	# Enable y-sorting so scattered decorations sort correctly against each
	# other AND against units/trees in sibling subtrees.
	y_sort_enabled = true
	scatter()

# The effective zone kind: parent Zone's kind, or own `kind` if standalone.
func effective_kind() -> Zone.Kind:
	var p := get_parent()
	if p is Zone:
		return (p as Zone).kind
	return kind

# The effective scatter area: own `area` if set, else parent Zone's area.
func effective_area() -> ScatterArea:
	if area:
		return area
	var p := get_parent()
	if p is Zone:
		return (p as Zone).area
	return null

func _decoration_pool() -> Array:
	if decorations.size() > 0:
		return decorations
	if decoration:
		return [decoration]
	return []

# Filters a pool for this zone's kind: OPEN zones drop colliding props.
func _filter_for_kind(pool: Array) -> Array:
	if effective_kind() != Zone.Kind.OPEN:
		return pool
	var filtered: Array = []
	for scene in pool:
		if scene and not _is_colliding(scene):
			filtered.append(scene)
	return filtered

func _is_colliding(scene: PackedScene) -> bool:
	var inst := scene.instantiate()
	var colliding := inst is PhysicsBody2D
	inst.free()
	return colliding

func scatter() -> void:
	_clear()
	var pool := _filter_for_kind(_decoration_pool())
	var scatter_area := effective_area()
	if pool.is_empty() or not scatter_area or count <= 0:
		return
	var companion_pool := _filter_for_kind(companions)

	var rng := RandomNumberGenerator.new()
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()

	for p in _poisson_points(scatter_area, rng):
		_spawn(pool[rng.randi() % pool.size()], p)
		if not companion_pool.is_empty() and rng.randf() < companion_chance:
			var n := rng.randi_range(companion_count.x, companion_count.y)
			for i in n:
				var angle := rng.randf() * TAU
				var dist := rng.randf() * companion_radius
				var cp := p + Vector2(cos(angle), sin(angle)) * dist
				# Keep companions inside the zone — a near-edge decoration
				# must not fling companions outside the scatter area.
				if scatter_area.contains(cp):
					_spawn(companion_pool[rng.randi() % companion_pool.size()], cp)

# Poisson-disk placement: random points, each rejected if closer than `radius`
# to an already-placed point. Gives blue-noise — even spacing, no clumps, and
# (unlike a grid) no row/column structure. If `count` can't be placed at the
# target radius, the radius relaxes so the count is always met.
func _poisson_points(scatter_area: ScatterArea, rng: RandomNumberGenerator) -> Array[Vector2]:
	if count <= 0:
		return []
	var b := scatter_area.bounds()
	# Natural spacing if `count` points evenly tiled the area.
	var natural := sqrt(maxf(b.size.x * b.size.y, 1.0) / float(count))
	var radius := spacing * natural

	var points: Array[Vector2] = []
	var fails := 0
	while points.size() < count:
		var p := scatter_area.random_point(rng)
		var ok := true
		for q in points:
			if p.distance_to(q) < radius:
				ok = false
				break
		if ok:
			points.append(p)
			fails = 0
		else:
			fails += 1
			# Couldn't fit at this radius — relax it and keep going.
			if fails > 30:
				radius *= 0.85
				fails = 0
	return points

func _spawn(scene: PackedScene, pos: Vector2) -> void:
	var instance: Node2D = scene.instantiate()
	instance.position = pos
	add_child(instance)

func _clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _regenerate_with_new_seed() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	rng_seed = rng.randi_range(1, 2147483647)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if _decoration_pool().is_empty():
		warnings.append("decoration / decorations is not set — nothing will be scattered.")
	if not effective_area():
		warnings.append("no area — set one, or place this under a Zone with an area.")
	return warnings

func _set_decoration(v: PackedScene) -> void:
	decoration = v
	_on_property_changed()

func _set_decorations(v: Array[PackedScene]) -> void:
	decorations = v
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

func _set_spacing(v: float) -> void:
	spacing = v
	_on_property_changed()

func _set_kind(v: Zone.Kind) -> void:
	kind = v
	_on_property_changed()

func _set_companions(v: Array[PackedScene]) -> void:
	companions = v
	_on_property_changed()

func _set_companion_chance(v: float) -> void:
	companion_chance = v
	_on_property_changed()

func _set_companion_count(v: Vector2i) -> void:
	companion_count = v
	_on_property_changed()

func _set_companion_radius(v: float) -> void:
	companion_radius = v
	_on_property_changed()

func _on_property_changed() -> void:
	update_configuration_warnings()
	if is_inside_tree():
		scatter()
	queue_redraw()

func _draw() -> void:
	if Engine.is_editor_hint():
		var a := effective_area()
		if a:
			a.draw_boundary(self)
