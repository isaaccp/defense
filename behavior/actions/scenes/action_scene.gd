extends Node2D

class_name ActionScene

var action_def: ActionDef

var owner_name: String
# From Body components.
var attributes_component: AttributesComponent
var side_component: SideComponent

func initialize(owner_name_: String, action_def_: ActionDef, attributes_component_: AttributesComponent, side_component_: SideComponent):
	owner_name = owner_name_
	action_def = action_def_
	attributes_component = attributes_component_
	side_component = side_component_
