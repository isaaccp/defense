extends Node2D

class_name BehaviorComponent

const component: StringName = &"BehaviorComponent"

signal behavior_updated(action: ActionDef.Id, target: Target)

@export_group("Required")
@export var body: CharacterBody2D
@export var navigation_agent: NavigationAgent2D
@export var action_sprites: Node2D
@export var animation_player: AnimationPlayer
@export var sprite: Sprite2D
@export var side_component: SideComponent
@export var attributes_component: AttributesComponent
@export var status_component: StatusComponent

@export_group("Optional")
# If set, behavior is obtained through there.
@export var persistent_game_state_component: PersistentGameStateComponent
@export var health_component: HealthComponent
@export var logging_component: LoggingComponent
@export var behavior: Behavior:
	get:
		if persistent_game_state_component:
			return persistent_game_state_component.state.behavior
		if behavior:
			assert(behavior.resource_local_to_scene, "Resource must be local to scene")
		return behavior

@export_group("Debug")
@export var rule: Rule
@export var target: Target
@export var action: Action
@export var action_cooldowns: Dictionary
# Keep track of time so we can do pause-aware stuff.
@export var elapsed_time: float = 0.0
# How often to check whether a higher-priority action should
# stop an abortable action.
var abortable_action_check_period = 0.1
var next_abortable_action_check_time: float

var running = false
var able_to_act = true

func _ready():
	status_component.able_to_act_changed.connect(_on_able_to_act_changed)
func run():
	behavior.prepare(body, side_component)
	running = true

func _on_able_to_act_changed(can_act: bool):
	able_to_act = can_act
	if not can_act:
		_interrupt()

func _interrupt():
	if action:
		_log("interrupted %s" % action.def.name())
		action.action_finished()

func _physics_process(delta: float):
	if not running:
		return

	if health_component and health_component.is_dead:
		return

	elapsed_time += delta

	assert(behavior, "Missing behavior")

	if not able_to_act:
		return

	# For change detection.
	var prev_action_id = _action_id(action)
	var prev_target = target

	# If action is finished, clear everything so we re-evaluate.
	if action and action.finished:
		_on_action_finished(action)
		rule = null
		action = null
		target = null
	# After this point, if action is still set, we can assume is not finished.
	if not rule or (action.abortable and next_abortable_action_check_time < elapsed_time):
		var result = behavior.choose(action_cooldowns, elapsed_time)
		if not result.is_empty():
			if result.rule != rule or not result.target.equals(target) or action.finished:
				rule = result.rule
				_log("Rule #%d: %s" % [result.id, rule])
				target = result.target
				if action:
					_log("preempted %s" % action.def.name())
					action.action_finished()
					_on_action_finished(action)
				action = SkillManager.make_runnable_action(rule.action)
				action.initialize(target, body, navigation_agent, action_sprites, side_component, attributes_component, status_component, logging_component)
		if action and action.abortable:
			next_abortable_action_check_time = elapsed_time + abortable_action_check_period
	_emit_updated_if_changed(prev_action_id, prev_target)
	# No rule implies no action.
	if rule:
		action.physics_process(delta)
	# Always run this to update animation, etc.
	_post_action()

func _on_action_finished(action: Action):
	assert(action.finished)
	if action.cooldown > 0:
		var eligible_at = elapsed_time + action.cooldown
		action_cooldowns[action.def.id] = eligible_at
		_log("%s: %0.1f cooldown, eligible at %0.2f" % [ action.def.name(), action.cooldown, eligible_at])

static func _action_id(action: Action) -> ActionDef.Id:
	if action:
		return action.def.id
	return ActionDef.Id.UNSPECIFIED

func _emit_updated_if_changed(prev_action_id: ActionDef.Id, prev_target: Target):
	# Log here if we become idle as it's the easiest way.
	var action_id = _action_id(action)
	if prev_action_id != action_id or prev_target != target:
		if rule == null:
			_log("Idle: Could not find any eligible rules")
		behavior_updated.emit(action_id, target)

func _post_action():
	if body.velocity.length() < 0.1:
		animation_player.play("idle")
	else:
		animation_player.play("run")
	if not is_zero_approx(body.velocity.x):
		sprite.flip_h = body.velocity.x < 0

func _log(message: String):
	if not logging_component:
		return
	logging_component.add_log_entry(LoggingComponent.LogType.BEHAVIOR, message)
