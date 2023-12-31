extends Node

class_name StatusComponent

const component: StringName = &"StatusComponent"

@export_group("Required")
# For statuses that cause damage.
@export var health_component: HealthComponent

@export_group("Debug")
# Used to keep detailed state about statuses. Keyed by (action_id, status_id) so
# multiple actions can provide a status without removing it too early.
@export var status_metadata: Dictionary
# Map of current statuses mapping to Dictionary of actions that provide it.
@export var current_statuses: Dictionary
# Keep track of time to know when to expire.
@export var elapsed_time: float = 0.0

signal statuses_changed(statuses: Array)
	
class StatusState extends RefCounted:
	# Remains until explicitly removed.
	var permanent: bool
	# Gets removed after this time.
	var expiration_time: float
	
	func _init(permanent_: bool, expiration_time_: float):
		permanent = permanent_
		expiration_time = expiration_time_

	func is_expired(elapsed_time: float):
		return not permanent and expiration_time < elapsed_time
	
static func _key(action_id: ActionDef.Id, status_id: StatusDef.Id) -> Dictionary:
	return {&"action": action_id, &"status": status_id}

func _process(delta: float):
	_expire_statuses()
	elapsed_time += delta

func set_status(action_id: ActionDef.Id, status_id: StatusDef.Id, time: float):
	var changed = false
	# Update status state.
	var key = _key(action_id, status_id)
	var new_status_state: StatusState
	if time < 0:
		new_status_state = StatusState.new(true, -1)
	else:
		new_status_state = StatusState.new(false, elapsed_time + time)
	status_metadata[key] = new_status_state
	# Update current statuses.
	if not current_statuses.has(status_id):
		current_statuses[status_id] = {}
		changed = true
	current_statuses[status_id][action_id] = true
	if changed:
		statuses_changed.emit(get_statuses())

func remove_status(action_id: ActionDef.Id, status_id: StatusDef.Id):
	# Delete status state.
	var key = _key(action_id, status_id)
	status_metadata.erase(key)
	# If this was the last action providing a status, remove status.
	if current_statuses.has(status_id):
		var status_data = current_statuses[status_id]
		status_data.erase(action_id)
		if status_data.is_empty():
			current_statuses.erase(status_id)
			statuses_changed.emit(get_statuses())

# TODO: If Godot gets better at Dictionary typing, make return type Array[StatusDef.Id]
func get_statuses() -> Array:
	return current_statuses.keys()

func _expire_statuses():
	for key in status_metadata.keys():
		if status_metadata[key].is_expired(elapsed_time):
			remove_status(key.action, key.status)

func adjusted_speed(base_speed: float) -> int:
	var speed = base_speed
	for status in get_statuses():
		if status == StatusDef.Id.SWIFTNESS:
			speed *= 1.5
	return speed
	
func adjusted_health(base_health: int) -> int:
	return base_health

func adjusted_damage_multiplier(base_damage_multiplier: float) -> float:
	var damage_multiplier = base_damage_multiplier
	for status in get_statuses():
		if status == StatusDef.Id.STRENGTHENED:
			damage_multiplier *= 2.0
	return damage_multiplier
