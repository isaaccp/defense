extends Node2D

class_name ActionScene

var action_def: ActionDef

# From Body components.
var attributes_component: AttributesComponent
var side_component: SideComponent

func initialize(action_def_: ActionDef, attributes_component_: AttributesComponent, side_component_: SideComponent):
	action_def = action_def_
	attributes_component = attributes_component_
	side_component = side_component_
