extends Effect

var poisoned_params: PoisonedParams
var tick_timer: float = 0.0

func initialize(params: EffectParams) -> void:
	poisoned_params = params as PoisonedParams
	assert(poisoned_params)

func on_process(delta: float) -> void:
	tick_timer += delta
	while tick_timer >= poisoned_params.tick_rate:
		tick_timer -= poisoned_params.tick_rate
		var damage_comp = Component.get_or_null(bearer, DamageComponent.component)
		if damage_comp:
			var hit = HitEffect.new()
			hit.damage = poisoned_params.damage_per_tick
			hit.damage_type = preload("res://game_logic/damage_types/poison.tres")
			hit.attack_type = preload("res://game_logic/attack_types/magical.tres")
			damage_comp.process_hit(hit)
