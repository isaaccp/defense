extends Action

func _init():
	distance = 50

func physics_process(entity: BehaviorEntity, target: Node2D, delta: float):
	var dir = (target.position - entity.position).normalized()
	var velocity = dir * entity.speed
	entity.move_and_collide(velocity * delta)
