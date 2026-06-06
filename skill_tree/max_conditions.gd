extends Object

class_name MaxConditions

# Static helper for the per-rule condition-count cap, which is gated by
# meta-skills: default cap is 1, "Compound Conditions" unlocks 2, "Triple
# Conditions" unlocks 3. Both the behavior editor UI and the sim validator
# call here so there's one source of truth.

const COMPOUND := &"Compound Conditions"
const TRIPLE := &"Triple Conditions"

static func cap_for(acquired_skills: SkillTreeState) -> int:
	if not acquired_skills:
		return 1
	var n := 1
	if acquired_skills.full or acquired_skills.skills_by_name.has(COMPOUND):
		n = 2
	if acquired_skills.full or acquired_skills.skills_by_name.has(TRIPLE):
		n = 3
	return n

# Variant for sim/JSON paths where the acquired set is a Dictionary of
# StringName -> true (the shape sim_runner builds internally).
static func cap_for_set(acquired_set: Dictionary, full: bool) -> int:
	if full:
		return 3
	var n := 1
	if acquired_set.has(COMPOUND):
		n = 2
	if acquired_set.has(TRIPLE):
		n = 3
	return n
