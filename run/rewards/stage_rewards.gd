@tool
extends Resource

class_name StageRewards

## The reward sets offered at this stage. Player picks one set and
## receives all rewards inside.
@export var sets: Array[RewardSet]
