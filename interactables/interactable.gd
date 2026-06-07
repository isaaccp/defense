@tool
extends Actor

class_name Interactable

## What kind of interactable this is. Used by target selectors to filter.
## Keep strictly to what's currently in use — add values only when adding the
## corresponding game content.
enum Kind {
	UNSPECIFIED,
	CHEST,
}

@export var kind: Kind = Kind.UNSPECIFIED

# True once it has been opened and shouldn't be a valid target anymore.
var opened: bool = false

## Called when an actor finishes the Open channel on this interactable.
## Subclasses override to apply the effect (gold, rescue, etc.).
func open(_actor: Actor) -> void:
	opened = true
	destroyed = true
