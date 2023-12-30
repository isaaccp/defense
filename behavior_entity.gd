extends CharacterBody2D

class_name BehaviorEntity

@export var speed: float
@export var max_hit_points: int

@onready var navigation_agent = $NavigationAgent2D
@onready var action_sprites = $ActionSprites

# Mostly should be set through set_behavior(), but exported for visibility and
# debugging.
@export_group("debug")
@export var behavior: Behavior
@export var rule: Rule
@export var target: Node2D
@export var action: Action
@export var hit_points: int:
	set(value):
		if hit_points != value:
			hit_points = value
			health_updated.emit(hit_points, max_hit_points)

@export var destroyed = false
# Keep track of time so we can do pause/freeze-aware stuff.
var elapsed_time: float = 0.0
# How often to check whether a higher-priority action should
# stop an abortable action.
var abortable_action_check_period = 0.1
var next_abortable_action_check_time = -1

# Need to skip first physics_frame for navigation.
var first = true

signal health_updated(hit_points: int, max_hit_points: int)

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(is_instance_valid(navigation_agent), "Must have a NavigationAgent2D node")
	assert(is_instance_valid(action_sprites), "Must have an ActionSprites node")
	hit_points = max_hit_points

func set_behavior(behavior_: Behavior):
	behavior = behavior_
	
func _physics_process(delta: float):
	if first:
		first = false
		return
	
	if destroyed:
		return
	
	elapsed_time += delta
		
	# TODO: Remove this, for now some enemies don't have behavior.
	if not behavior:
		return
	if not rule or (action.abortable and next_abortable_action_check_time > elapsed_time) or action.finished:
		var result = behavior.choose(self)
		# There is nothing to do.
		if result.is_empty() and (not action or action.finished):
			return
		if not result.is_empty():
			if result.rule != rule or result.target != target or action.finished:
				rule = result.rule
				print("%s: Switched to rule: %s" % [name, rule])
				target = result.target
				if action and not action.finished:
					action.action_finished()
				action = ActionManager.make_action(rule.action)
				action.set_entity(self)
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
	if velocity.length() < 0.1:
		play_anim("idle")
	else:
		play_anim("run")
	if not is_zero_approx(velocity.x):
		flip_h(velocity.x < 0)

func take_damage(damage: int) -> void:
	if hit_points < damage:
		hit_points = 0
	else:
		hit_points -= damage
	if hit_points <= 0:
		destroyed = true
		play_anim("death")
	
func is_enemy(entity: BehaviorEntity) -> bool:
	assert(false, "Should never be called")
	return true
	
func enemies() -> Array[Node]:
	assert(false, "Should never be called")
	return []

func play_anim(animation: String) -> void:
	assert(false, "Should never be called")

func flip_h(flip: bool) -> void:
	assert(false, "Should never be called")
