@tool
extends Node

class_name StatusComponent

const component: StringName = &"StatusComponent"

@export_group("Optional")
@export var logging_component: LoggingComponent

# Used to keep detailed state about statuses. Keyed by (action_id, status name)
# so multiple actions can provide a status without removing it too early.
var status_metadata: Dictionary
# Map of current statuses mapping to Dictionary of actions that provide it.
var current_statuses: Dictionary
# Keep track of time to know when to expire.
var elapsed_time: float = 0.0

signal status_added(status: StatusDef)
signal status_removed(status_name: StringName)
signal statuses_changed(statuses: Array[StringName])

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

func _key(action_name: StringName, status_name: StringName) -> Dictionary:
	return {&"action": action_name, &"status": status_name}

func _process(delta: float):
	_expire_statuses()
	elapsed_time += delta

func set_status(action_name: StringName, status: StatusDef, time: float):
	var time_str = "%0.1fs" % time if time > 0 else "during action"
	_log("%s provided by %s (%s)" % [status.name, action_name, time_str])
	var changed = false
	# Update status state.
	var key = _key(action_name, status.name)
	var new_status_state: StatusState
	if time < 0:
		new_status_state = StatusState.new(true, -1)
	else:
		new_status_state = StatusState.new(false, elapsed_time + time)
	status_metadata[key] = new_status_state
	# Update current statuses.
	if not current_statuses.has(status.name):
		current_statuses[status.name] = {}
		changed = true
	current_statuses[status.name][action_name] = true
	if changed:
		_log("%s status added" % status.name)
		status_added.emit(status)
		statuses_changed.emit(get_statuses())

func remove_status(action_name: StringName, status_name: StringName, expired = false):
	var reason = "expired" if expired else "removed"
	_log("%s (from %s) %s" % [status_name, action_name, reason])
	# Delete status state.
	var key = _key(action_name, status_name)
	status_metadata.erase(key)
	# If this was the last action providing a status, remove status.
	if current_statuses.has(status_name):
		var status_data = current_statuses[status_name]
		status_data.erase(action_name)
		if status_data.is_empty():
			current_statuses.erase(status_name)
			_log("%s status removed" % status_name)
			status_removed.emit(status_name)
			statuses_changed.emit(get_statuses())

func get_statuses() -> Array[StringName]:
	var statuses: Array[StringName] = []
	statuses.assign(current_statuses.keys())
	return statuses

func _expire_statuses():
	for key in status_metadata.keys():
		if status_metadata[key].is_expired(elapsed_time):
			remove_status(key.action, key.status, true)

func _log(message: String):
	if not logging_component:
		return
	logging_component.add_log_entry(LoggingComponent.LogType.STATUS, message)
