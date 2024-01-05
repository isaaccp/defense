extends Resource

class_name Action

@export_group("Debug")
@export var def: ActionDef

# Whether this action can be aborted.
# If that's the case, we'll check if higher priority actions can be
# executed periodically during execution.
@export var abortable = false
# Target type supported by this action. As we only have one, put it here
# by now with a default value. If later we have moer, we'll have to move
# it to the ActionDef so e.g. the script editor can know which target types
# are acceptable for a given action.
@export var target_type_supported = Target.Type.NODE
# How far can this action be taken.
@export var max_distance = 10_000_000
# How close can this action be taken.
# Don't make this negative as it may be squared to calculate distance.
@export var min_distance = 0.0
# How long until this action can be triggered again.
# Ignored if negative.
@export var cooldown = -1.0
# Whether this action is considered finished.
@export var finished = false


var target: Target
var body: CharacterBody2D
var action_sprites: Node2D
var navigation_agent: NavigationAgent2D
var side_component: SideComponent
var attributes_component: AttributesComponent
var status_component: StatusComponent
var logging_component: LoggingComponent

func initialize(target_: Target, body_: CharacterBody2D, navigation_agent_: NavigationAgent2D,
				action_sprites_: Node2D, side_component_: SideComponent,
				attributes_component_: AttributesComponent,
				status_component_: StatusComponent,
				logging_component_: LoggingComponent) -> void:
	target = target_
	assert(target.type == target_type_supported, "Unsupported target type: %s" % target.type)
	body = body_
	navigation_agent = navigation_agent_
	action_sprites = action_sprites_
	side_component = side_component_
	attributes_component = attributes_component_
	status_component = status_component_
	logging_component = logging_component_
	post_initialize()

# Called before the first invocation of physics_process.
# 'target' is as initially returned when choosing an action.
# If you schedule work with await, make sure to check for
# "finished" after awaiting and exiting.
func post_initialize():
	pass

# Runs the appropriate physics process for entity.
# 'target' may have decayed, e.g. a 'node' pointed to by 'target' may no
# longer exist. Must check for it by hand.
func physics_process(delta: float):
	pass

# It is important that it's only called once.
func action_finished():
	if finished:
		return
	finished = true

func _initialize_action_scene(action_scene: ActionScene) -> void:
	action_scene.initialize(body.name, def, attributes_component, side_component, logging_component)

func action_log(message: String):
	if not logging_component:
		return
	var full_message = "%s: %s" % [def.name(), message]
	logging_component.add_log_entry(LoggingComponent.LogType.ACTION, full_message)
