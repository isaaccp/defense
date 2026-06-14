extends TargetActorConditionEvaluator

class_name TargetingAllyTargetActorConditionEvaluator

func _is_valid_target(their_target: Actor) -> bool:
	return true

func evaluate(target: Actor) -> bool:
	var bc = Component.get_or_null(target, BehaviorComponent.component) as BehaviorComponent
	if not bc or not bc.target or not bc.target.valid():
		return false
	if bc.target.type != Target.Type.ACTOR:
		return false
	var their_target: Actor = bc.target.actor as Actor
	if not their_target:
		return false
		
	if not _is_valid_target(their_target):
		return false
		
	var their_side = Component.get_or_null(their_target, SideComponent.component) as SideComponent
	if not side_component or not their_side:
		return false
		
	return side_component.is_ally(their_side)
