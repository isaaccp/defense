extends Node2D

class_name HealthComponent

const component: StringName = &"HealthComponent"

signal health_updated(update: HealthUpdate)
signal died

class HealthUpdate extends RefCounted:
	var health: int
	var prev_health: int
	var max_health: int
	var is_heal: bool

	func _to_string():
		return "[health: %d -> %d (max: %d) is_heal: %s]" % [prev_health, health, max_health, is_heal]

enum ShowHealth {
	NEVER,
	WHEN_NOT_FULL,
	ALWAYS,
}

@export_group("Required")
@export var attributes_component: AttributesComponent
@export var show_health: ShowHealth

@export_group("Optional")
@export var logging_component: LoggingComponent

@export_group("Debug")
@export var max_health: int:
	set(value):
		max_health = value
		if health > max_health:
			_update_health(max_health, true, "max health reduced")

@export var health: int
@export var is_dead: bool = false

func _ready():
	if show_health in [ShowHealth.NEVER, ShowHealth.WHEN_NOT_FULL]:
		%HealthBar.hide()
	_initialize.call_deferred()

func _initialize():
	max_health = attributes_component.health
	_update_health(max_health)

# Returns true if hit caused any damage.
func process_hit(hit_effect: HitEffect) -> bool:
	var adjusted_damage = hit_effect.adjusted_damage()
	var damage_str = "%d" % adjusted_damage
	# If damage was 0 to begin with, just return.
	if adjusted_damage <= 0:
		_log_blocked_damage(damage_str)
		return false
	var after_armor_damage = max(0, adjusted_damage - attributes_component.armor)
	if after_armor_damage != adjusted_damage:
		damage_str = "%d (%s - %d (armor))" % [after_armor_damage, damage_str, attributes_component.armor]
	if after_armor_damage <= 0:
		_log_blocked_damage(damage_str)
		return false
	var after_resistance_damage = after_armor_damage
	# TODO: Apply resistances.
	if after_resistance_damage != after_armor_damage:
		# Update damage_str.
		pass
	if after_resistance_damage <= 0:
		_log_blocked_damage(damage_str)
		return false
	var new_health = health - after_resistance_damage
	_update_health(new_health, true, damage_str)
	return true

func _log_blocked_damage(damage_details: String):
	_log("dmg: %s" % damage_details)

func _update_health(new_health: int, should_log: bool = false, message: String = ""):
	var prev_health = health
	health = clampi(new_health, 0, max_health)
	var update = HealthUpdate.new()
	update.health = health
	update.prev_health = prev_health
	update.is_heal = health > prev_health
	update.max_health = max_health
	health_updated.emit(update)
	if should_log:
		_log("Health: %d -> %d, dmg: %s" % [update.prev_health, update.health, message])
	if health == 0 and not is_dead:
		_log("Died")
		is_dead = true
		died.emit()

func _log(message: String):
	if not logging_component:
		return
	logging_component.add_log_entry(LoggingComponent.LogType.HEALTH, message)

func _on_health_updated(update: HealthUpdate):
	if show_health == ShowHealth.NEVER:
		return
	if show_health == ShowHealth.WHEN_NOT_FULL:
		%HealthBar.visible = not (update.health == update.max_health)
	%HealthBar.max_value = update.max_health
	%HealthBar.value = update.health

func _on_died():
	%HealthBar.visible = false
