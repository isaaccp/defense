extends Node2D

class_name ActionScene

var action_def: ActionDef

var owner_name: String
# From Body components.
var attributes_component: AttributesComponent
var side_component: SideComponent
var logging_component: LoggingComponent

func initialize(owner_name_: String, action_def_: ActionDef, attributes_component_: AttributesComponent, side_component_: SideComponent, logging_component_: LoggingComponent):
	owner_name = owner_name_
	action_def = action_def_
	attributes_component = attributes_component_
	side_component = side_component_
	logging_component = logging_component_

func action_scene_log(message: String):
	if not logging_component:
		return
	var full_message = "%s: %s" % [name, message]
	logging_component.add_log_entry(LoggingComponent.LogType.ACTION, full_message)
