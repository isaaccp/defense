extends Resource

class_name Action

@export_group("Debug")
@export var def: ActionDef

# Whether this action can be aborted.
# If that's the case, we'll check if higher priority actions can be
# executed periodically during execution.
@export var abortable = false
# How far can this action be taken.
@export var distance = -1
# Whether this action is considered finished.
@export var finished = false
# Whether this action can hurt allies.
@export var friendly_fire = false

# Reference to entity running this action.
var entity: BehaviorEntity

func set_entity(entity_: BehaviorEntity) -> void:
	entity = entity_
	
# Returns true if the preconditions needed to execute this action are met.
func can_be_executed(target: Node2D) -> bool:
	return distance < 0 or entity.position.distance_to(target.position) < distance
	
# Runs the appropriate physics process for entity.
func physics_process(target: Node2D, delta: float):
	pass

func action_finished():
	finished = true
