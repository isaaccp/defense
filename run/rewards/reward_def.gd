@tool
extends Resource

class_name RewardDef

## Human-readable name shown on the reward stage screen.
@export var display_name: String = ""
## Short description shown alongside the outcome.
@export var description: String = ""

## Applies the reward to the run state. Returns an outcome string suitable
## for display (e.g. "Knight healed 30 → 48"). Subclasses override.
func apply(_run_save_state: RunSaveState) -> String:
	push_error("RewardDef.apply must be overridden")
	return ""
