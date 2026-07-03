extends RefCounted

class_name AoeTargetingHelper

# Best-placement search for area-of-effect actions: returns the position
# (and rotation) where the action's shape catches the most enemies, plus
# that count. Used by both Can Hit Enemies (condition) and Most Enemies
# Position (target selector); they share a per-frame cache so the work runs
# at most once per (actor, action) per physics frame even when both are
# evaluated.

class Placement:
	var transform: Transform2D
	var count: int = 0
	var valid: bool = false

# Cache key: [actor_id, action_name]. Value: { "frame": int, "placement": Placement }.
static var _cache: Dictionary = {}

static func best_placement(actor: Actor, action: Action, side: SideComponent, is_ally: bool = false) -> Placement:
	var frame := Engine.get_physics_frames()
	var key = [actor.get_instance_id(), action.def.skill_name, is_ally]
	var cached = _cache.get(key)
	if cached and cached.frame == frame:
		return cached.placement
	var placement := _compute(actor, action, side, is_ally)
	_cache[key] = {"frame": frame, "placement": placement}
	return placement

static func _compute(actor: Actor, action: Action, side: SideComponent, is_ally: bool = false) -> Placement:
	var def := action.def
	if def.aoe_placement == ActionDef.AoePlacement.NONE or not def.aoe_shape:
		push_error("AoeTargetingHelper: action '%s' missing aoe_shape / aoe_placement" % def.name())
		return Placement.new()

	var targets: Array[Vector2] = []
	var units = side.allies() if is_ally else side.enemies()
	for u in units:
		if is_instance_valid(u) and not (u as Actor).destroyed:
			targets.append((u as Node2D).global_position)
	if targets.is_empty():
		return Placement.new()

	var candidates := _candidate_transforms(actor, action, targets)
	if candidates.is_empty():
		return Placement.new()

	# Spatial grid keyed by cell coord -> indices into `targets`. Cell size
	# matches the shape's bounding radius so a candidate only needs to
	# consult cells whose AABB overlaps the bounding circle.
	var cell_size: float = max(_shape_bounding_radius(def.aoe_shape), 16.0)
	var grid: Dictionary = {}
	for i in targets.size():
		var p := targets[i]
		var c := Vector2i(int(floor(p.x / cell_size)), int(floor(p.y / cell_size)))
		if not grid.has(c):
			grid[c] = PackedInt32Array()
		grid[c].append(i)

	var best := Placement.new()
	for t in candidates:
		var count := _count_in_shape_via_grid(def.aoe_shape, t, targets, grid, cell_size)
		if count > best.count:
			best.transform = t
			best.count = count
			best.valid = true
	return best

static func _candidate_transforms(actor: Actor, action: Action, enemies: Array[Vector2]) -> Array[Transform2D]:
	var def := action.def
	var caster: Vector2 = actor.global_position
	var transforms: Array[Transform2D] = []
	match def.aoe_placement:
		ActionDef.AoePlacement.SELF:
			if _is_rotationally_invariant(def.aoe_shape, def.aoe_offset):
				transforms.append(Transform2D(0.0, caster))
			else:
				for e in enemies:
					var d := e - caster
					var angle := 0.0 if d == Vector2.ZERO else d.angle()
					transforms.append(_make_transform(caster, angle, def.aoe_offset))
		ActionDef.AoePlacement.POSITION_FREE:
			var r: float = float(action.max_distance)
			var r2: float = r * r
			for e in enemies:
				if (e - caster).length_squared() <= r2:
					transforms.append(_make_transform(e, 0.0, def.aoe_offset))
	return transforms

static func _make_transform(origin: Vector2, angle: float, offset: Vector2) -> Transform2D:
	# Offset is applied in the shape's local space so it rotates with the
	# shape (e.g. (25, 0) keeps the shape 25 units 'in front' of caster).
	return Transform2D(angle, origin).translated_local(offset)

static func _is_rotationally_invariant(shape: Shape2D, offset: Vector2) -> bool:
	return offset == Vector2.ZERO and shape is CircleShape2D

static func _shape_bounding_radius(shape: Shape2D) -> float:
	if shape is CircleShape2D:
		return (shape as CircleShape2D).radius
	if shape is CapsuleShape2D:
		return (shape as CapsuleShape2D).height * 0.5
	if shape is RectangleShape2D:
		return ((shape as RectangleShape2D).size * 0.5).length()
	push_error("Unsupported aoe_shape type: %s" % shape)
	return 0.0

static func _count_in_shape_via_grid(shape: Shape2D, t: Transform2D, enemies: Array[Vector2], grid: Dictionary, cell_size: float) -> int:
	var origin := t.origin
	var bounding := _shape_bounding_radius(shape)
	var min_c := Vector2i(int(floor((origin.x - bounding) / cell_size)), int(floor((origin.y - bounding) / cell_size)))
	var max_c := Vector2i(int(floor((origin.x + bounding) / cell_size)), int(floor((origin.y + bounding) / cell_size)))
	var count := 0
	for cx in range(min_c.x, max_c.x + 1):
		for cy in range(min_c.y, max_c.y + 1):
			var bucket = grid.get(Vector2i(cx, cy))
			if bucket == null:
				continue
			for idx in bucket:
				if _point_in_shape(enemies[idx], shape, t):
					count += 1
	return count

static func _point_in_shape(p: Vector2, shape: Shape2D, t: Transform2D) -> bool:
	# Transform world point into shape-local space.
	var local: Vector2 = t.affine_inverse() * p
	if shape is CircleShape2D:
		var r := (shape as CircleShape2D).radius
		return local.length_squared() <= r * r
	if shape is CapsuleShape2D:
		var c := shape as CapsuleShape2D
		# Godot capsules are oriented along local Y; height includes the caps.
		var half: float = max(0.0, c.height * 0.5 - c.radius)
		var y: float = clamp(local.y, -half, half)
		var nearest := Vector2(0.0, y)
		return (local - nearest).length_squared() <= c.radius * c.radius
	if shape is RectangleShape2D:
		var ext := (shape as RectangleShape2D).size * 0.5
		return abs(local.x) <= ext.x and abs(local.y) <= ext.y
	return false
