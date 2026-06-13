extends Effect

func on_damage_taken(_damage_taken: int, _attacker_name: String) -> void:
	var enemies = bearer.get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.actor_name == _attacker_name:
			var vitals = Component.get_or_null(enemy, VitalsComponent.component) as VitalsComponent
			if vitals:
				vitals.apply_vital_change(VitalsComponent.VitalType.HEALTH, -2.0, true)
			break
