extends Effect

const ranged_attack = preload("res://game_logic/attack_types/ranged.tres")

var projectile_ward_params: ProjectileWardParams

func initialize(params: EffectParams) -> void:
	projectile_ward_params = params as ProjectileWardParams
	assert(projectile_ward_params)
	
func modify_attributes(attributes: Attributes) -> void:
	assert(projectile_ward_params)
	var resistance = Resistance.new()
	resistance.percentage = projectile_ward_params.ranged_attack_resistance
	resistance.attack_type = ranged_attack
	attributes.add_resistance(resistance)
