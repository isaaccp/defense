@tool
extends Interactable

class_name Chest

## Emitted when the chest is opened. The owning Level listens and
## forwards to its own gold_earned signal, which Run aggregates onto
## RunSaveState.
signal gold_earned(amount: int)



## Gold granted when the chest is opened.
@export var gold_amount: int = 25



const gold_chests_skill = preload("res://skill_tree/meta_skills/gold_chests.tres")

func meets_requirements(unlocked_skills: SkillTreeState) -> bool:
	return unlocked_skills and unlocked_skills.available(gold_chests_skill)

func _init() -> void:
	kind = Enum.InteractableKind.CHEST
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
