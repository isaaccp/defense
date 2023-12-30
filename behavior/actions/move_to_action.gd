extends Action

func _init():
	abortable = true
	
# Runs the appropriate physics process for entity.
func physics_process(target: Node2D, delta: float):
	if not is_instance_valid(target):
		action_finished()
		return
	var dir = (target.position - entity.position).normalized()
	var velocity = dir * entity.speed
	entity.move_and_collide(velocity * delta)
