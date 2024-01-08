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
			health = max_health

@export var health: int:
	set(value):
		var prev_health = health
		health = clampi(value, 0, max_health)
		var update = HealthUpdate.new()
		update.health = health
		update.prev_health = prev_health
		update.is_heal = health > prev_health
		update.max_health = max_health
		health_updated.emit(update)
		# Do not log on initial heal.
		if initial_heal:
			initial_heal = false
		else:
			_log("Health: %d -> %d" % [update.prev_health, update.health])
@export var is_dead: bool = false

# To avoid
var initial_heal = true

func _ready():
	if show_health in [ShowHealth.NEVER, ShowHealth.WHEN_NOT_FULL]:
		%HealthBar.hide()
	_initialize.call_deferred()

func _initialize():
	max_health = attributes_component.health
	heal_full()

func heal_full():
	health = max_health

func heal(dmg: int):
	damage(-dmg)

func damage(dmg: int):
	health -= dmg
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
