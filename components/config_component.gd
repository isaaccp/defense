@tool
extends Node

class_name ConfigComponent

const component: StringName = &"ConfigComponent"


@export_group("Required")
@export var config: UnitConfig
