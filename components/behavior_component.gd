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
@export var health_component: HealthComponent
@export var behavior: Behavior

@export_group("Debug")
@export var rule: Rule
@export var target: Target
@export var action: Action

# Keep track of time so we can do pause/freeze-aware stuff.
var elapsed_time: float = 0.0
# How often to check whether a higher-priority action should
# stop an abortable action.
var abortable_action_check_period = 0.1
var next_abortable_action_check_time: float

# Need to skip first physics_frame for navigation.
var first = true

func _ready():
	pass

func _physics_process(delta: float):
	if first:
		first = false
		return
	
	if health_component and health_component.is_dead:
		return
	
	elapsed_time += delta
	
	assert(behavior, "Missing behavior")
		
	# For change detection.
	var prev_action_id = _action_id(action)
	var prev_target = target
	
	# If action is finished, clear everything so we re-evaluate.
	if action and action.finished:
		rule = null
		action = null
		target = null
	# After this point, if action is still set, we can assume is not finished.
	if not rule or (action.abortable and next_abortable_action_check_time < elapsed_time):
		var result = behavior.choose(body, side_component)
		if not result.is_empty():
			if result.rule != rule or not result.target.equals(target) or action.finished:
				rule = result.rule
				print("%s: Switched to rule: %s" % [get_parent().name, rule])
				target = result.target
				if action:
					action.action_finished()
				action = ActionManager.make_action(rule.action)
				action.initialize(target, body, navigation_agent, action_sprites, side_component, attributes_component, status_component)
		if action and action.abortable:
			next_abortable_action_check_time = elapsed_time + abortable_action_check_period
	_emit_updated_if_changed(prev_action_id, prev_target)
	# No rule implies no action.
	if not rule:
		return
	action.physics_process(delta)
	_post_action()
	
static func _action_id(action: Action) -> ActionDef.Id:
	if action:
		return action.def.id
	return ActionDef.Id.UNSPECIFIED

func _emit_updated_if_changed(prev_action_id: ActionDef.Id, prev_target: Target):
	var action_id = _action_id(action)
	if prev_action_id != action_id or prev_target != target:
		behavior_updated.emit(action_id, target)

func _post_action():
	if body.velocity.length() < 0.1:
		animation_player.play("idle")
	else:
		animation_player.play("run")
	if not is_zero_approx(body.velocity.x):
		sprite.flip_h = body.velocity.x < 0
