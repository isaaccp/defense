@tool
extends Node2D

class_name HealthComponent

const component: StringName = &"HealthComponent"

signal hit(hit_effect: HitEffect)
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
			update_health(max_health, true, "max health reduced")

@export var health: int
@export var is_dead: bool = false

# If different than zero, initial health will be set to this, otherwise to
# health obtained from attributes.
var initial_health = 0
var running = false

func _ready():
	if Engine.is_editor_hint():
		return
	if show_health in [ShowHealth.NEVER, ShowHealth.WHEN_NOT_FULL]:
		%HealthBar.hide()
	_initialize.call_deferred()

func _initialize():
	max_health = attributes_component.health
	if initial_health == 0:
		initial_health = max_health
	update_health(initial_health)

func run():
	running = true

func stop():
	running = false

func _log_blocked_damage(damage_details: String):
	_log("damage blocked", damage_details)

func update_health(new_health: int, should_log: bool = false, message: String = "", tooltip: String = ""):
	var prev_health = health
	health = clampi(new_health, 0, max_health)
	var update = HealthUpdate.new()
	update.health = health
	update.prev_health = prev_health
	update.is_heal = health > prev_health
	update.max_health = max_health
	health_updated.emit(update)
	if should_log:
		if update.is_heal:
			if new_health > max_health:
				tooltip = "Health limited to max health (%d)" % max_health
		_log("Health: %d -> %d, %s" % [update.prev_health, update.health, message], tooltip)
	if health == 0 and not is_dead:
		_log("Died", tooltip)
		is_dead = true
		died.emit()

func _log(message: String, tooltip: String = ""):
	if not logging_component:
		return
	logging_component.add_log_entry(LoggingComponent.LogType.HEALTH, message, tooltip)

func _on_health_updated(update: HealthUpdate):
	if show_health == ShowHealth.NEVER:
		return
	if show_health == ShowHealth.WHEN_NOT_FULL:
		%HealthBar.visible = not (update.health == update.max_health)
	%HealthBar.max_value = update.max_health
	%HealthBar.value = update.health

func _on_died():
	%HealthBar.visible = false

static func get_or_null(node) -> HealthComponent:
	return Component.get_or_null(node, component) as HealthComponent

static func get_or_die(node) -> HealthComponent:
	var c = get_or_null(node)
	assert(c)
	return c
