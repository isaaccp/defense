@tool
extends Node

const actions = preload("res://skill_tree/skill_type_collections/action_collection.tres")

# Try moving this to the Resource at some point again, and then
# just load the action collection here.
const action_scripts = {
	ActionDef.Id.MOVE_TO: preload("res://behavior/actions/move_to_action.gd"),
	ActionDef.Id.SWORD_ATTACK: preload("res://behavior/actions/sword_attack_action.gd"),
	ActionDef.Id.BOW_ATTACK: preload("res://behavior/actions/bow_attack_action.gd"),
	ActionDef.Id.CHARGE: preload("res://behavior/actions/charge_action.gd"),
	ActionDef.Id.MULTI_SHOT: preload("res://behavior/actions/multi_shot_action.gd"),
	ActionDef.Id.HEAL: preload("res://behavior/actions/heal_action.gd"),
}

func make_action(action_def: ActionDef) -> Action:
	var action = action_scripts[action_def.id].new() as Action
	action.def = action_def
	return action

func all_actions() -> Array[ActionDef.Id]:
	var all: Array[ActionDef.Id] = []
	for id in action_scripts.keys():
		all.append(id as ActionDef.Id)
	return all
