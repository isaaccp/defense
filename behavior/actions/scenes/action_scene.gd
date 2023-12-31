extends Node2D

class_name ActionScene

# From Body components.
var attributes_component: AttributesComponent
var side_component: SideComponent

func initialize(attributes_component_: AttributesComponent, side_component_: SideComponent):
	attributes_component = attributes_component_
	side_component = side_component_
