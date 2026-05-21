extends Action

# Instant, logic-only action: drops the BehaviorComponent's preferred target,
# then finishes immediately. Use it in a rule whose condition decides the
# commitment is no longer worth keeping (e.g. the target retreated). The slot
# also auto-clears when the target dies, so this is for the "still alive but
# no longer worth it" case.

func post_initialize():
	var bc := BehaviorComponent.get_or_null(actor)
	if bc:
		bc.clear_preferred_target("rule")
	action_finished()

func description() -> String:
	return "Drops the current preferred target so the character resumes its normal behavior."
