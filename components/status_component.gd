extends Node

class_name StatusComponent

@export_group("Required")
# For statuses that cause damage.
@export var health_component: HealthComponent

@export_group("Debug")
@export var statuses: Dictionary
@export var elapsed_time: float = 0.0

class StatusState extends RefCounted:
	# Remains until explicitly removed.
	var permanent: bool
	# Gets removed after this time.
	var expiration: float
	
	func _init(permanent_: bool, expiration_: float):
		permanent = permanent_
		expiration = expiration_

	func is_expired(elapsed_time: float):
		return not permanent and expiration < elapsed_time
		
func _process(delta: float):
	# TODO: Probably have a cache for statuses/adjusted_stats and clear it
	# every frame if this ends up taking too much time.
	elapsed_time += delta
	
func set_status(status_id: StatusDef.Id, time: float):
	var new_status_state: StatusState
	if time < 0:
		new_status_state = StatusState.new(true, -1)
	else:
		new_status_state = StatusState.new(false, elapsed_time + time)
	statuses[status_id] = new_status_state

func get_statuses() -> Array[StatusDef.Id]:
	var valid_statuses: Array[StatusDef.Id] = []
	for status in statuses.keys():
		if statuses[status].is_expired(elapsed_time):
			statuses.erase(status)
			continue
		valid_statuses.append(status as StatusDef.Id)
	return valid_statuses

# TODO: Maybe have some way to detect if this same status was set in some
# other way, or e.g. have the key in status be (status, source) so if
# multiple sources cast it we don't remove it just because one source
# removes it.
func remove_status(status_id: StatusDef.Id):
	statuses.erase(status_id)

func adjusted_speed(base_speed: float) -> int:
	var speed = base_speed
	for status in get_statuses():
		if status == StatusDef.Id.FAST:
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
