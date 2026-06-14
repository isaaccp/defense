extends TargetActorConditionEvaluator

class_name HasStatusTargetActorConditionEvaluator

func evaluate(target: Actor) -> bool:
	var status_comp = Component.get_or_null(target, StatusComponent.component) as StatusComponent
	var has = false
	var status_def = def.params.status if def.params.placeholder_set(SkillParams.PlaceholderId.STATUS) else null
	
	if status_comp and status_def:
		has = status_comp.has_status(status_def.name)
	
	var invert = false
	if def.params.placeholder_set(SkillParams.PlaceholderId.BOOL_VALUE):
		invert = not def.params.bool_value.value
		
	if invert:
		return not has
	return has
