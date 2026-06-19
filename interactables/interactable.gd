@tool
extends Actor

class_name Interactable

@export var kind: Enum.InteractableKind = Enum.InteractableKind.UNSPECIFIED

# True once it has been opened and shouldn't be a valid target anymore.
var opened: bool = false

## Called when an actor finishes the Open channel on this interactable.
## Subclasses override to apply the effect (gold, rescue, etc.).
func open(_actor: Actor) -> void:
	opened = true
	destroyed = true

## Returns true if this interactable should be spawned based on unlocked skills.
func meets_requirements(_unlocked_skills: SkillTreeState) -> bool:
	return true
