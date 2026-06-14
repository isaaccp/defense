extends Action

const TAUNTED_DEF = preload("res://effects/statuses/taunted.tres")

func _init():
	prepare_time = 0.2
	focus_cost = 2
	max_distance = 250
	cooldown = 8.0

func post_prepare():
	if target and target.valid() and target.type == Target.Type.ACTOR:
		var target_actor = target.actor
		var hurtbox = HurtboxComponent.get_or_null(target_actor)
		if hurtbox and hurtbox.can_handle_collision():
			var hit_effect = HitEffect.new()
			hit_effect.action_name = def.name()
			hit_effect.status = TAUNTED_DEF
			hit_effect.status_params = TauntedParams.make(actor)
			hit_effect.status_duration = 5.0
			hurtbox.handle_collision(actor.actor_name, "Taunt", hit_effect)
	
	action_finished()

func description() -> String:
	return "Taunts an enemy, forcing them to attack the taunter for 5 seconds."
