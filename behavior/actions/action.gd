extends Resource

class_name Action

@export_group("Debug")
@export var def: ActionDef
@export var abortable = false
	
# Returns true if the preconditions needed to execute this action are met, e.g.
# if this is a melee attack it can only be run if the target is within melee
# range.
func can_be_executed(entity: BehaviorEntity, target: Node2D) -> bool:
	return false
	
# Runs the appropriate physics process for entity.
func physics_process(entity: BehaviorEntity, target: Node2D, delta: float):
	pass
