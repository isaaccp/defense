@tool
extends Resource

class_name SpawnProviderConfig

# TODO: Deprecate PackedScene-based spawning in favor of enemy config.
@export var spawn: PackedScene
@export var spawn_enemy_config: EnemyConfig
