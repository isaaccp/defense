extends Effect

func on_damage_taken(_damage_taken: int, _attacker_name: String) -> void:
	var behavior = Component.get_or_null(bearer, BehaviorComponent.component) as BehaviorComponent
	if behavior:
		for action_name in behavior.action_cooldowns:
			var eligible_at = behavior.action_cooldowns[action_name]
			if eligible_at > behavior.elapsed_time:
				behavior.action_cooldowns[action_name] = eligible_at - 0.5
