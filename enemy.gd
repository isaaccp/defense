extends BehaviorEntity

class_name Enemy

@export var sprite: Sprite2D

func _ready():
	super()
	print(action_sprites)
	
func is_enemy(entity: BehaviorEntity) -> bool:
	return entity.is_in_group(Groups.CHARACTERS)

func enemies() -> Array[Node]:
	return get_tree().get_nodes_in_group(Groups.CHARACTERS)

func play_anim(anim: String) -> void:
	# TODO: Implement.
	pass

func flip_h(flip: bool) -> void:
	sprite.flip_h = flip
