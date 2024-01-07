extends Resource

class_name Action

@export_group("Debug")
@export var def: ActionDef

const MaxDistance = 10_000_000

# Whether this action can be aborted.
# If that's the case, we'll check if higher priority actions can be
# executed periodically during execution.
@export var abortable = false
# How far can this action be taken.
@export var max_distance = MaxDistance
# How close can this action be taken.
# Don't make this negative as it may be squared to calculate distance.
@export var min_distance = 0.0
# Behavior to use when using a node_target_selector.
# If filter_with_distance is set to true, each eligible node
# will be filtered by distance, then first one will be returned.
# This ensures a node will be returned if any are eligible.
# If filter_with_distance is set to false, then the target selector
# will first choose one node, then it'll apply the distance check to it
# and return invalid target if it failed.
# This latter behavior makes sense for e.g. "move to" action where you want
# to stop triggering it if you are too close to the closest enemy, but not
# switch to the "second closest" enemy.
@export var filter_with_distance = true
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
	assert(def.compatible_with_target(target.type), "Unsupported target type: %s" % target.type)
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

# Can call this after awaiting to:
#  * check if action is finished
#  * optionally check if target is invalid (in which case it'll finish action for you)
#  * if it returns false, you should return immediately
func _after_await_check(check_target: bool) -> bool:
	if finished:
		# Nothing to clean up, as clean up should already have
		# happened when action_finished() was called.
		return false
	if not is_instance_valid(body):
		action_finished()
		return false
	if check_target and not target.valid():
		action_finished()
		return false
	return true

func action_log(message: String):
	if not logging_component:
		return
	var full_message = "%s: %s" % [def.name(), message]
	logging_component.add_log_entry(LoggingComponent.LogType.ACTION, full_message)

func full_description() -> String:
	return "%s\n%s" % [description(), attributes()]

func description() -> String:
	return "<missing description for %s>" % def.name()

func _range_str() -> String:
	var max_str = "inf" if max_distance == MaxDistance else "%0.1f" % max_distance
	return "Range: (%0.1f,%s)" % [min_distance, max_str]

func attributes():
	var attrs = ""
	attrs += _range_str() + "\n"
	if cooldown > 0:
		attrs += "Cooldown: %0.1f\n" % cooldown
	if abortable:
		attrs += "Can be preempted"
	attrs += "Supported Target Types: %s" % def.supported_target_types_str()
	return attrs
