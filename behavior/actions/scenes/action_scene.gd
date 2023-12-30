extends Node2D

class_name ActionScene

signal entity_hit(entity: BehaviorEntity)

func get_entity(area: Area2D) -> BehaviorEntity:
	var current = area.get_parent()
	while is_instance_valid(current):
		if current is BehaviorEntity:
			return current
	assert(false, "Should never happen")
	return null

# Figure out how to deal with friendly fire, etc.
func _on_area_2d_area_entered(area: Area2D):
	var entity = get_entity(area)
	entity_hit.emit(entity)
