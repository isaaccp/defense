@tool
extends Resource

class_name Target

enum Type {
	## Should never be set.
	UNSPECIFIED,
	## Returns one Actor.
	ACTOR,
	## Returns an Array of Actor.
	ACTORS,
	## Returns a Vector2.
	POSITION,
}

var type: Type
var actor: Actor:
	get:
		if type != Type.ACTOR:
			print("unexpected actor get")
		if not is_instance_valid(actor):
			actor = null
		return actor
var actors: Array[Actor]:
	get:
		if type != Type.ACTORS:
			print("unexpected actors get")
		# Never return invalid stuff.
		var new_actors: Array[Actor] = []
		for actor in actors:
			if is_instance_valid(actor):
				new_actors.append(actor)
		actors = new_actors
		return actors
var pos: Vector2:
	get:
		if type != Type.POSITION:
			print("unexpected pos get")
		return pos

# Helper so we don't have to set up ACTORS in additions to
# ACTOR in sorters, as they are the same from the point of
# view of sorters.
func sorter_type() -> Type:
	if type == Type.ACTORS:
		return Type.ACTOR
	return type

func valid() -> bool:
	if type == Type.UNSPECIFIED:
		return false
	if type == Type.ACTOR:
		return actor != null and is_instance_valid(actor)
	if type == Type.ACTORS:
		return not actors.is_empty()
	if type == Type.POSITION:
		return true
	return false

## Whether the target still meets the initial condition.
func meets_condition() -> bool:
	return true

func equals(other: Target) -> bool:
	if type == other.type:
		match type:
			Type.ACTOR:
				return actor == other.actor
			Type.ACTORS:
				# To not trigger getter repeatedly.
				var these_actors = actors
				var other_actors = other.actors
				if these_actors.size() != other_actors.size():
					return false
				for i in range(these_actors.size()):
					if these_actors[i] != other_actors[i]:
						return false
				return true
			Type.POSITION:
				return pos.is_equal_approx(other.pos)
	return false

func _to_string():
	match type:
		Type.ACTOR:
			return actor.actor_name
		Type.ACTORS:
			var actor_names = actors.map(func(a): return a.actor_name)
			return "[%s]" % ",".join(actor_names)
		Type.POSITION:
			return "(%0.1f,%0.1f)" % [pos.x, pos.y]

func position() -> Vector2:
	match type:
		Type.ACTOR:
			return actor.position
		Type.POSITION:
			return pos
		_:
			assert(false, "Unexpected call to position()")
	return Vector2.ZERO

static func make_invalid() -> Target:
	return Target.new()

static func target_type_str(target_type: Target.Type) -> String:
	return Type.keys()[target_type]
