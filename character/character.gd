extends BehaviorEntity

class_name Character

@export_group("debug")
@export var id: Enum.CharacterId
@export var idx: int
@export var peer_id: int
@export var spec: CharacterSpec

func _ready():
	# TODO: Hack for now.
	if behavior == null:
		behavior = spec.default_behavior

func short_name() -> String:
	return "%s (%d)" % [Enum.character_id_string(id), idx]
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func is_enemy(entity: BehaviorEntity) -> bool:
	return entity.is_in_group(Groups.ENEMIES)

func enemies() -> Array[Node]:
	return get_tree().get_nodes_in_group(Groups.ENEMIES)
