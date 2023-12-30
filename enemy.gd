extends BehaviorEntity

func is_enemy(entity: BehaviorEntity) -> bool:
	return entity.is_in_group(Groups.CHARACTERS)

func enemies() -> Array[Node]:
	return get_tree().get_nodes_in_group(Groups.CHARACTERS)
