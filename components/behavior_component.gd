@tool
extends Node2D

class_name BehaviorComponent

const component: StringName = &"BehaviorComponent"

signal behavior_updated(action_name: StringName, target: Target)

@export_group("Required")
# TODO: Change to Actor once we have a way to get the body through a component.
@export var body: CharacterBody2D
@export var navigation_agent: NavigationAgent2D
@export var action_sprites: Node2D
@export var sprite: Sprite2D
@export var animation_component: AnimationComponent
@export var side_component: SideComponent
@export var attributes_component: AttributesComponent
@export var status_component: StatusComponent
@export var effect_actuator_component: EffectActuatorComponent

@export_group("Optional")
# If set, behavior is obtained through there.
@export var persistent_game_state_component: PersistentGameStateComponent
@export var health_component: HealthComponent
@export var logging_component: LoggingComponent
@export var stored_behavior: StoredBehavior:
	get:
		if Engine.is_editor_hint():
			return stored_behavior
		if persistent_game_state_component:
			var gameplay_character = persistent_game_state_component.state as GameplayCharacter
			return gameplay_character.behavior
		return stored_behavior

var rule: Rule
var target: Target
var action: Action
var action_cooldowns: Dictionary
# Keep track of time so we can do pause-aware stuff.
var elapsed_time: float = 0.0
# How often to check whether a higher-priority action should
# stop an abortable action.
var abortable_action_check_period = 0.1
var next_abortable_action_check_time: float

var running = false
var able_to_act = true

var behavior: Behavior

func _ready():
	if Engine.is_editor_hint():
		return
	effect_actuator_component.able_to_act_changed.connect(_on_able_to_act_changed)

func run():
	var actor = (body as Node2D) as Actor
	behavior = SkillManager.restore_behavior(stored_behavior)
	behavior.prepare(actor, side_component)
	running = true

func stop():
	_interrupt()
	running = false

func _on_able_to_act_changed(can_act: bool):
	able_to_act = can_act
	if not can_act:
		_interrupt()

func _interrupt():
	if action:
		var prev_action_name = _action_name(action)
		var prev_target = target
		_log("interrupted %s" % action.def.name())
		action.action_finished()
		_on_action_finished()
		_emit_updated_if_changed(prev_action_name, prev_target)

func _physics_process(delta: float):
	if not running:
		return

	if health_component and health_component.is_dead:
		return

	elapsed_time += delta

	assert(behavior, "Missing behavior")

	if able_to_act:
		# For change detection.
		var prev_action_name = _action_name(action)
		var prev_target = target

		# If action is finished, clear everything so we re-evaluate.
		if action and action.finished:
			_on_action_finished()
		# After this point, if action is still set, we can assume is not finished.
		var abortable_check_needed = action and action.abortable and next_abortable_action_check_time < elapsed_time
		if not rule or abortable_check_needed:
			var result = behavior.choose(action_cooldowns, elapsed_time)
			if not result.is_empty():
				if result.rule != rule or not result.target.equals(target) or action.finished:
					if action:
						_log("preempted %s" % action.def.name())
						action.action_finished()
						_on_action_finished()
					rule = result.rule
					target = result.target
					action = result.action
					_log("Rule #%d: %s" % [result.id, rule.string_with_target(target)])
					action.initialize(target, body, navigation_agent, action_sprites, side_component, attributes_component, status_component, logging_component, effect_actuator_component)
			if action and action.abortable:
				next_abortable_action_check_time = elapsed_time + abortable_action_check_period
		_emit_updated_if_changed(prev_action_name, prev_target)
		# No rule implies no action.
		if rule:
			action.physics_process(delta)
	# Always run this to update animation, etc.
	_post_action()

func _on_action_finished():
	assert(action.finished)
	if action.cooldown > 0:
		var eligible_at = elapsed_time + action.cooldown
		action_cooldowns[action.def.skill_name] = eligible_at
		_log("%s: %0.1f cooldown, eligible at %0.2f" % [ action.def.name(), action.cooldown, eligible_at])
	rule = null
	action = null
	target = null

func _action_name(action: Action) -> StringName:
	if action:
		return action.def.skill_name
	return ActionDef.NoAction

func _emit_updated_if_changed(prev_action_name: StringName, prev_target: Target):
	# Log here if we become idle as it's the easiest way.
	var action_name = _action_name(action)
	if prev_action_name != action_name or prev_target != target:
		if rule == null:
			_log("Idle: Could not find any eligible rules")
		behavior_updated.emit(action_name, target)

func _post_action():
	if body.velocity.length() < 0.1:
		animation_component.play_animation("idle")
	else:
		animation_component.play_animation("run")
	if not is_zero_approx(body.velocity.x):
		sprite.flip_h = body.velocity.x < 0

func _log(message: String):
	if not logging_component:
		return
	logging_component.add_log_entry(LoggingComponent.LogType.BEHAVIOR, message)

static func get_or_null(node) -> BehaviorComponent:
	return Component.get_or_null(node, component) as BehaviorComponent

static func get_or_die(node) -> BehaviorComponent:
	var c = get_or_null(node)
	assert(c)
	return c

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	if not get_parent() is Node2D:
		return warnings
	return warnings
