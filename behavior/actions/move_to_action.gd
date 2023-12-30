extends Action

func can_be_executed(entity: BehaviorEntity, target: Node2D) -> bool:
	return true
	
# Runs the appropriate physics process for entity.
func physics_process(entity: BehaviorEntity, target: Node2D, delta: float):
	var dir = (target.position - entity.position).normalized()
	var velocity = dir * entity.speed
	entity.move_and_collide(velocity * delta)
