@tool
extends Node

## A component that holds a target.
class_name TargetComponent

const component = &"TargetComponent"

## Set through script.
var action_target: ActionTarget

static func get_or_null(node) -> TargetComponent:
	return Component.get_or_null(node, component) as TargetComponent

static func get_or_die(node) -> TargetComponent:
	var c = get_or_null(node)
	assert(c)
	return c
