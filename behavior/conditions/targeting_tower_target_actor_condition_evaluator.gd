extends TargetActorConditionEvaluator

# True iff the candidate actor's behavior is currently targeting a tower.
# Pairs with Set Preferred Target — gating commitment on "this enemy is
# actively going for the objective" rather than physical distance. Predictive
# (catches an archer the moment they pick the tower as their target) and
# naturally ignores enemies that are already engaged with one of our
# characters (their target is us, not the tower).

func evaluate(target: Actor) -> bool:
	var bc := BehaviorComponent.get_or_null(target) as BehaviorComponent
	if not bc or not bc.target or not bc.target.valid():
		return false
	if bc.target.type != Target.Type.ACTOR:
		return false
		
	if not bc.action or not bc.action.def:
		return false
	var tags = bc.action.def.tags
	var is_attack = ActionTag.Tag.ATTACK in tags
	var is_debuff = ActionTag.Tag.DEBUFF in tags
	if not (is_attack or is_debuff):
		return false
		
	var their_target := bc.target.actor
	if their_target == null:
		return false
	if not SideComponent.is_tower_node(their_target):
		return false
	return true
