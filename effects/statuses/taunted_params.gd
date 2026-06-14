extends EffectParams

class_name TauntedParams

# We do not export Actor because it's a runtime-only reference, not a static config.
var source_actor: Actor

static func make(source_actor_: Actor) -> TauntedParams:
	var params = TauntedParams.new()
	params.source_actor = source_actor_
	return params
