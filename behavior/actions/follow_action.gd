extends MoveActionBase

# Move toward the target but stop at a configurable distance — meant for
# support characters who want to stay close enough to cast on an ally but
# not be drawn into melee. min_distance is parameterised via the rule's
# float_value (e.g. "stay 150 units away from ally"); falls back to
# FOLLOW_DEFAULT_DISTANCE if no param is set.

const FOLLOW_DEFAULT_DISTANCE: float = 100.0

func post_make():
	if def.params.placeholder_set(SkillParams.PlaceholderId.FLOAT_VALUE):
		min_distance = def.params.get_placeholder_value(SkillParams.PlaceholderId.FLOAT_VALUE)
	else:
		min_distance = FOLLOW_DEFAULT_DISTANCE

func post_initialize():
	super()
	# MoveActionBase finishes when NavigationAgent2D reports "navigation
	# finished," which uses its own target_desired_distance — wire that to
	# our min_distance so Follow actually stops at the configured range
	# instead of walking up to the target.
	navigation_agent.target_desired_distance = min_distance

func description() -> String:
	return "Moves toward the target, stopping when within %0.0f units." % min_distance
