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

@export_group("Required")
@export var attributes_component: AttributesComponent

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
		# Do not emit/log on initial heal.
		if initial_heal:
			initial_heal = false
			return
		var update = HealthUpdate.new()
		update.health = health
		update.prev_health = prev_health
		update.is_heal = health > prev_health
		update.max_health = max_health
		_log("Health: %d -> %d" % [update.prev_health, update.health])
		health_updated.emit(update)
@export var is_dead: bool = false

# To avoid
var initial_heal = true

func _ready():
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
