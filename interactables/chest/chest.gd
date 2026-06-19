@tool
extends Interactable

class_name Chest

## Emitted when the chest is opened. The owning Level listens and
## forwards to its own gold_earned signal, which Run aggregates onto
## RunSaveState.
signal gold_earned(amount: int)

const default_milestone = preload("res://milestones/defs/gold_chests_unlock.tres")

## Gold granted when the chest is opened.
@export var gold_amount: int = 25

## Optional milestone ID required for this chest to spawn. If empty, uses the default gold_chests_unlock milestone.
@export var required_milestone: StringName = &""

func meets_requirements(unlocked_milestones: Dictionary) -> bool:
	var milestone_to_check = required_milestone if required_milestone != &"" else default_milestone.id
	return unlocked_milestones.get(milestone_to_check, false)

func _init() -> void:
	kind = Interactable.Kind.CHEST
	actor_name = "Chest"

func open(_actor: Actor) -> void:
	if opened:
		return
	super.open(_actor)
	gold_earned.emit(gold_amount)
	# Hide the visual so it reads as looted. Defer free so any in-flight
	# action references resolve cleanly.
	visible = false
	queue_free()
