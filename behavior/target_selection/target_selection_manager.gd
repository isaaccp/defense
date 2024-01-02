@tool
extends Object

class_name TargetSelectionManager

static var target_selections = {
	# TODO: Refactor all those so they return a list of nodes to
	# filter through condition instead of having to do it in each.
	TargetSelectionDef.Id.CLOSEST_ENEMY: preload("res://behavior/target_selection/target_selection_closest_enemy.gd"),
	TargetSelectionDef.Id.TOWER: preload("res://behavior/target_selection/target_selection_tower.gd"),
	TargetSelectionDef.Id.SELF: preload("res://behavior/target_selection/target_selection_self.gd"),
}

static func select_target(target_selection_def: TargetSelectionDef, evaluator: TargetNodeConditionEvaluator, action: Action, body: CharacterBody2D, side_component: SideComponent) -> Target:
	var target_selection = target_selections[target_selection_def.id]
	return target_selection.select_target(target_selection_def, evaluator, action, body, side_component)

static func all_target_selections() -> Array[TargetSelectionDef.Id]:
	var all: Array[TargetSelectionDef.Id] = []
	for id in target_selections.keys():
		all.append(id as TargetSelectionDef.Id)
	return all
