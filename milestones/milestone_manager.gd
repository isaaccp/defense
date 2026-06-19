class_name MilestoneManager

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
		if current >= def.required_count:
			save_state.unlocked_milestones[def.id] = true
			print("Milestone unlocked: ", def.id)
