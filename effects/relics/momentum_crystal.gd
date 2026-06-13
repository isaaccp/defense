extends Effect

func on_enemy_killed(_victim_name: String) -> void:
	var status = Component.get_or_null(bearer, StatusComponent.component) as StatusComponent
	if status:
		status.set_status(&"Momentum Crystal", preload("res://effects/statuses/swiftness.tres"), SwiftnessParams.make(2.0), 3.0)
