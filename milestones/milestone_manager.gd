class_name MilestoneManager

class MilestoneProgressDelta extends RefCounted:
	var def: MilestoneDef
	var previous: int
	var current: int
	var required: int
	var unlocked: bool
	var was_unlocked: bool

var defs: Array[MilestoneDef] = []
var save_state: SaveState

func _init(save_state: SaveState, library: MilestoneLibrary):
	self.save_state = save_state
	if library:
		for ach in library.milestones:
			if ach:
				defs.append(ach)

func evaluate_level_end(level_stats: AggregateStats):
	for def in defs:
		if def.phase != MilestoneDef.EvaluationPhase.LEVEL_END:
			continue
		_evaluate_def(def, level_stats)

func evaluate_run_end():
	for def in defs:
		if def.phase != MilestoneDef.EvaluationPhase.RUN_END:
			continue
		_evaluate_def(def, null)

func _evaluate_def(def: MilestoneDef, level_stats: AggregateStats):
	if save_state.unlocked_milestones.get(def.id, false):
		return
	var progress = def.evaluate(level_stats, save_state.run_save_state.stats, save_state.global_stats)
	if progress > 0:
		var current = save_state.milestone_progress.get(def.id, 0)
		current += progress
		save_state.milestone_progress[def.id] = current

## Called at the end of the run to officially unlock milestones.
## Returns a list of milestones that gained progress this run, including their unlock status.
func process_unlocks(run_save_state: RunSaveState) -> Array[MilestoneProgressDelta]:
	var deltas: Array[MilestoneProgressDelta] = []
	for def in defs:
		var previous = run_save_state.starting_milestone_progress.get(def.id, 0)
		var current = save_state.milestone_progress.get(def.id, 0)
		var was_unlocked = run_save_state.unlocked_milestones.get(def.id, false)
		
		var delta = MilestoneProgressDelta.new()
		delta.def = def
		delta.previous = previous
		delta.current = current
		delta.required = def.required_count
		delta.was_unlocked = was_unlocked
		delta.unlocked = was_unlocked
		
		# Only unlock if it wasn't already unlocked, and we met the requirement
		if current >= def.required_count and not save_state.unlocked_milestones.get(def.id, false):
			save_state.unlocked_milestones[def.id] = true
			delta.unlocked = true
			
			for skill in def.reward_skills:
				if skill and not save_state.unlocked_skills.available(skill):
					save_state.unlocked_skills.mark_available(skill)
			
		deltas.append(delta)
		
	return deltas
