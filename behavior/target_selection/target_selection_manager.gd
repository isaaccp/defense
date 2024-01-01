@tool
extends Object

class_name TargetSelectionManager

static var target_selections = {
	TargetSelectionDef.Id.CLOSEST_ENEMY: preload("res://behavior/target_selection/target_selection_closest_enemy.gd"),
	TargetSelectionDef.Id.TOWER: preload("res://behavior/target_selection/target_selection_tower.gd"),
}

static func select_target(body: CharacterBody2D, side_component: SideComponent, action: Action, target_selection_def: TargetSelectionDef) -> Target:
	var target_selection = target_selections[target_selection_def.id]
	return target_selection.select_target(body, side_component, action, target_selection_def)

static func all_target_selections() -> Array[TargetSelectionDef.Id]:
	var all: Array[TargetSelectionDef.Id] = []
	for id in target_selections.keys():
		all.append(id as TargetSelectionDef.Id)
	return all
