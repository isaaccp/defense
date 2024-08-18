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
# How long until post_prepare() gets invoked. See more details on
# post_prepare().
@export var prepare_time = -1.0
# If true, it'll check that target is still valid after prepare.
@export var need_valid_target_after_prepare = false
# How long until this action can be triggered again.
# Ignored if negative.
@export var cooldown = -1.0
# If true, the action will check periodically whether the target still
# meets the initial condition, and stop the action if it no longer does.
@export var finish_on_unmet_condition = false
# Whether this action is considered finished.
var finished = false
# Whether this action is in the prepare stage. It is automatically
# set to true on initialization if prepare_time is > 0. If you want
# to manually do preparation, set to true on _init().
var is_preparing = false

var target: Target
var actor: Actor
var body: CharacterBody2D
var action_sprites: Node2D
var navigation_agent: NavigationAgent2D
var side_component: SideComponent
var attributes_component: AttributesComponent
var status_component: StatusComponent
var logging_component: LoggingComponent
var effect_actuator_component: EffectActuatorComponent

static func make_runnable_action(action_def: ActionDef) -> Action:
	var action = action_def.action_script.new() as Action
	action.def = action_def
	return action

func _init():
	pass

func initialize(target_: Target, actor_: Actor, navigation_agent_: NavigationAgent2D,
				action_sprites_: Node2D, side_component_: SideComponent,
				attributes_component_: AttributesComponent,
				status_component_: StatusComponent,
				logging_component_: LoggingComponent,
				effect_actuator_component_: EffectActuatorComponent,
				character_body_component_: CharacterBodyComponent) -> void:
	target = target_
	assert(def.compatible_with_target(target.type), "Unsupported target type: %s" % target.type)
	actor = actor_
	body = character_body_component_.character_body
	navigation_agent = navigation_agent_
	action_sprites = action_sprites_
	side_component = side_component_
	attributes_component = attributes_component_
	status_component = status_component_
	logging_component = logging_component_
	effect_actuator_component = effect_actuator_component_
	if finish_on_unmet_condition:
		_start_condition_checker.call_deferred()
	if prepare_time > 0:
		is_preparing = true
		_schedule_post_prepare.call_deferred()
	post_initialize()

func _start_condition_checker():
	while not finished:
		await Global.get_tree().create_timer(0.25).timeout
		if not target.meets_condition():
			action_finished()

# Called before the first invocation of physics_process.
# 'target' is as initially returned when choosing an action.
# If you schedule work with await, make sure to check for
# "finished" after awaiting and exiting.
func post_initialize():
	# If the action doesn't require preparing (because prepare_time is < 0
	# and is_preparing wasn't explicitly set to true), immediately call
	# post_prepare(). This allows subclasses to put code in post_prepare()
	# regardless of whether other subclasses set prepare_time/is_preparing
	# or not.
	if not is_preparing:
		post_prepare.call_deferred()

func _schedule_post_prepare():
	await Global.get_tree().create_timer(prepare_time, false).timeout
	on_finished_preparing()

func on_finished_preparing():
	if not _after_await_check(need_valid_target_after_prepare):
		return
	if is_preparing:
		is_preparing = false
		post_prepare()

# If prepare_time is set, it'll be called that time after post_initialize().
# If is_preparing was set to true, explicitly, it'll be called when
# on_finished_preparing() is invoked.
# Otherwise, it'll be called deferred at the end of post_initialize().
func post_prepare():
	pass

# Runs the appropriate physics process for entity.
# 'target' may have decayed, e.g. a 'node' pointed to by 'target' may no
# longer exist. Must check for it by hand.
func physics_process(_delta: float):
	pass

# It is important that it's only called once.
# TODO: Document why
func action_finished():
	if finished:
		return
	finished = true

func _initialize_action_scene(action_scene: ActionScene) -> void:
	action_scene.initialize(actor.actor_name, def, target, attributes_component.attributes, side_component, logging_component, effect_actuator_component)

# Can call this after awaiting to:
#  * check if action is finished
#  * optionally check if target is invalid (in which case it'll finish action for you)
#  * if it returns false, you should return immediately
func _after_await_check(check_target: bool) -> bool:
	if finished:
		# Nothing to clean up, as clean up should already have
		# happened when action_finished() was called.
		return false
	if not is_instance_valid(actor):
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
	return "<missing description>"

func _range_str() -> String:
	var max_str = "inf" if max_distance == MaxDistance else "%0.1f" % max_distance
	return "Range: (%0.1f,%s)" % [min_distance, max_str]

func attack_direction(position_type: Target.PositionType = Target.PositionType.HURTBOX) -> Vector2:
	return (target_position(position_type) - actor.attack_position()).normalized()

func target_position(position_type: Target.PositionType = Target.PositionType.DEFAULT) -> Vector2:
	var action_target = ActionTarget.new(target, position_type)
	return action_target.target_position()

func attributes():
	var attrs = ""
	attrs += _range_str() + "\n"
	if cooldown > 0:
		attrs += "Cooldown: %0.1f\n" % cooldown
	if abortable:
		attrs += "Can be preempted\n"
	attrs += "Supported Target Types: %s" % def.supported_target_types_str()
	return attrs
