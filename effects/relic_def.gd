extends EffectDef

class_name RelicDef

@export var description: String
@export var icon: Texture2D
## True for relics that ship with a class's starting kit — those are part
## of class identity and should not be offered as random rewards.
## Excluded from the relic draft pool by RelicLibraryState.
@export var class_relic: bool = false
