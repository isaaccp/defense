extends Node2D

class_name BehaviorComponent

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
@export var target: Node2D
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
		
	# TODO: Remove this, for now some enemies don't have behavior.
	if not behavior:
		return
	if not rule or (action.abortable and next_abortable_action_check_time > elapsed_time) or action.finished:
		var result = behavior.choose(body, side_component)
		# There is nothing to do.
		if result.is_empty() and (not action or action.finished):
			return
		if not result.is_empty():
			if result.rule != rule or result.target != target or action.finished:
				rule = result.rule
				print("%s: Switched to rule: %s" % [get_parent().name, rule])
				target = result.target
				if action and not action.finished:
					action.action_finished()
				action = ActionManager.make_action(rule.action)
				action.initialize(body, navigation_agent, action_sprites, side_component, attributes_component, status_component)
		if action.abortable:
			next_abortable_action_check_time = elapsed_time + abortable_action_check_period
	if not rule:
		print("Unable to choose a rule for %s" % name)
		return
	# It is possible that the target dies while we are running the
	# action. The action must be able to deal with null target
	# (except on the first invocation of physics_process).
	if not is_instance_valid(target):
		target = null
	action.physics_process(target, delta)
	if body.velocity.length() < 0.1:
		animation_player.play("idle")
	else:
		animation_player.play("run")
	if not is_zero_approx(body.velocity.x):
		sprite.flip_h = body.velocity.x < 0
