extends BehaviorEntity

class_name Character

var character_id: Enum.CharacterId
var spec: CharacterSpec

func _ready():
	# TODO: Hack for now.
	if behavior == null:
		behavior = spec.default_behavior

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func is_enemy(entity: BehaviorEntity) -> bool:
	return entity.is_in_group(Groups.ENEMIES)

func enemies() -> Array[Node]:
	return get_tree().get_nodes_in_group(Groups.ENEMIES)
	
