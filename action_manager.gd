extends Object

class_name ActionManager

static var actions = {
	ActionDef.Id.MOVE_TO: preload("res://behavior/actions/move_to_action.gd"),
}

static func make_action(action_def: ActionDef) -> Action:
	var action = actions[action_def.id].new() as Action
	action.def = action_def
	return action
