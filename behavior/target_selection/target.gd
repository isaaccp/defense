extends Resource

class_name Target

enum Type {
	UNSPECIFIED,
	ACTOR,
}

var type: Type
var actor: Node2D:
	get:
		assert(type == Type.ACTOR)
		if not is_instance_valid(actor):
			actor = null
		return actor

func valid() -> bool:
	if type == Type.UNSPECIFIED:
		return false
	if type == Type.ACTOR:
		return actor != null and is_instance_valid(actor)
	return false

func equals(other: Target) -> bool:
	if type == other.type:
		if type == Type.ACTOR:
			return actor == other.actor
	return false

func _to_string():
	match type:
		Type.ACTOR:
			return actor.actor_name

func position() -> Vector2:
	match type:
		Type.ACTOR:
			return actor.position
		_:
			assert(false, "Unexpected call to position()")
	return Vector2.ZERO

static func make_invalid() -> Target:
	return Target.new()

static func make_actor_target(actor_: Node2D) -> Target:
	var target = Target.new()
	target.type = Type.ACTOR
	target.actor = actor_
	return target
