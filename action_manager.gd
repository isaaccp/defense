extends Object

class_name ActionManager

static var actions = {
	ActionDef.Id.MOVE_TO: preload("res://behavior/actions/move_to_action.gd"),
	ActionDef.Id.SWORD_ATTACK: preload("res://behavior/actions/sword_attack_action.gd"),
}

static func make_action(action_def: ActionDef) -> Action:
	var action = actions[action_def.id].new() as Action
	action.def = action_def
	return action

static func all_actions() -> Array[ActionDef.Id]:
	var all: Array[ActionDef.Id] = []
	for id in actions.keys():
		all.append(id as ActionDef.Id)
	return all
