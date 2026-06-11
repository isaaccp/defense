extends EffectDef

class_name RelicDef

@export var description: String
@export var icon: Texture2D
## True for relics that ship with a class's starting kit — those are part
## of class identity and should not be offered as random rewards.
## Excluded from the relic draft pool by RelicLibraryState.
@export var class_relic: bool = false

## Action skills this relic depends on to be meaningful. Empty = universal
## (eligible regardless of party composition). When non-empty, the relic
## is only drafted if at least one of these actions is in the run's
## `current unlocked` set — i.e. some party character could plausibly use
## the action. Filter happens in `RelicRewardDef.roll`.
@export var required_actions: Array[StringName]
