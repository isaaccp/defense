@tool
extends Resource

class_name RewardSet

## A set of rewards offered as one option at a reward stage. The player
## takes all rewards in the chosen set. For MVP each set is size 1; later
## sets can bundle multiple rewards.
@export var rewards: Array[RewardDef]
