extends RefCounted

class_name ActionTarget

var target: Target
var position_type: Target.PositionType

func _init(target: Target, position_type: Target.PositionType):
	self.target = target
	self.position_type = position_type

# This needs to be done here instead of in Target, as otherwise Target depends
# on HurtboxComponent which creates a lot of cyclical dependencies.
# It can't be done in Action either because then it'd require Action to be passed
# to ActionScene.
func target_position() -> Vector2:
	match target.type:
		Target.Type.ACTOR:
			if position_type == Target.PositionType.HURTBOX:
				var hurtbox = HurtboxComponent.get_or_null(target.actor)
				if hurtbox:
					return hurtbox.global_position
			return target.actor.position
		Target.Type.POSITION:
			return target.pos
		_:
			assert(false, "Unexpected call to position()")
	return Vector2.ZERO
