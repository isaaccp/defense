extends Object

class_name TargetSelectionManager

static var target_selections = {
	TargetSelectionDef.Id.CLOSEST_ENEMY: preload("res://behavior/target_selection/target_selection_closest_enemy.gd"),
}

static func select_target(entity: BehaviorEntity, target_selection_def: TargetSelectionDef) -> Node2D:
	var target_selection = target_selections[target_selection_def.id]
	return target_selection.select_target(entity, target_selection_def)
