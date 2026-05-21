extends Action

# Instant, logic-only action: commits the rule's selected target as the
# BehaviorComponent's preferred target, then finishes immediately. Pair it with
# a target selector + sort to choose what to commit (e.g. Enemy + Closest To
# Tower First). Placed below the "use preferred target" rules so it only runs
# when the slot is empty.

func post_initialize():
	var bc := BehaviorComponent.get_or_null(actor)
	if bc and target and target.type == Target.Type.ACTOR:
		bc.set_preferred_target(target.actor)
	action_finished()

func description() -> String:
	return "Commits the selected enemy as the preferred target — the character pursues it until it dies or is cleared."
