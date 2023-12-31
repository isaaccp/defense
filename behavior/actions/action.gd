extends Resource

class_name Action

@export_group("Debug")
@export var def: ActionDef

# Whether this action can be aborted.
# If that's the case, we'll check if higher priority actions can be
# executed periodically during execution.
@export var abortable = false
# How far can this action be taken.
@export var distance = -1
# Whether this action is considered finished.
@export var finished = false

var body: CharacterBody2D
var action_sprites: Node2D
var navigation_agent: NavigationAgent2D
var side_component: SideComponent
var attributes_component: AttributesComponent
var status_component: StatusComponent

func initialize(body_: CharacterBody2D, navigation_agent_: NavigationAgent2D,
				action_sprites_: Node2D, side_component_: SideComponent,
				attributes_component_: AttributesComponent,
				status_component_: StatusComponent) -> void:
	body = body_
	navigation_agent = navigation_agent_
	action_sprites = action_sprites_
	side_component = side_component_
	attributes_component = attributes_component_
	status_component = status_component_
	
# Returns true if the preconditions needed to execute this action are met.
func can_be_executed(target: Node2D) -> bool:
	return distance < 0 or body.position.distance_to(target.position) < distance
	
# Runs the appropriate physics process for entity.
func physics_process(target: Node2D, delta: float):
	pass

func action_finished():
	finished = true
