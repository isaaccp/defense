extends Effect

# Wizard class relic: Meditation
# Gain passive Focus per second while idle.

const FOCUS_REGEN_PER_SECOND: float = 1.0

func on_process(delta: float) -> void:
	var behavior := Component.get_or_null(bearer, BehaviorComponent.component) as BehaviorComponent
	if not behavior:
		return
		
	# Being "idle" means the behavior has not selected a rule (no action running)
	if behavior.rule == null:
		var vitals := Component.get_or_null(bearer, VitalsComponent.component) as VitalsComponent
		if vitals:
			vitals.apply_vital_change(VitalsComponent.VitalType.FOCUS, FOCUS_REGEN_PER_SECOND * delta, false)
