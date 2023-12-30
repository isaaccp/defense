extends Node2D

class_name BehaviorEntity

@export var speed = 60
@export var action_sprites: Node2D

# Mostly should be set through set_behavior(), but exported for visibility and
# debugging.
@export_group("debug")
@export var behavior: Behavior
@export var rule: Rule
@export var target: Node2D
@export var action: Action

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

#func set_behavior(behavior_: Behavior):
#	behavior = behavior_
	
func _physics_process(delta):
	# TODO: Remove this, for now some enemies don't have behavior.
	if not behavior:
		return
	# TODO: If action is abortable, we should only check every e.g. 0.1
	# seconds instead of every frame.
	if not rule or action.abortable or action.finished:
		var result = behavior.choose(self)
		# There is nothing to do.
		if result.is_empty() and (not action or action.finished):
			return
		if not result.is_empty():
			if result.rule != rule or result.target != target or action.finished:
				rule = result.rule
				print("Switched to rule: %s" % rule)
				target = result.target
				action = ActionManager.make_action(rule.action)
				action.set_entity(self)
	if not rule:
		print("Unable to choose a rule for %s" % name)
		return
	# It is possible that the target dies while we are running the
	# action. The action must be able to deal with null target
	# (except on the first invocation of physics_process).
	if not is_instance_valid(target):
		target = null
	action.physics_process(target, delta)

func is_enemy(entity: BehaviorEntity) -> bool:
	assert(false, "Should never be called")
	return true
	
func enemies() -> Array[Node]:
	assert(false, "Should never be called")
	return []
