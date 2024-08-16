extends Control

class_name HudEnemyView

var enemy: Enemy

signal view_log_requested(enemy: Enemy)

func initialize(enemy_: Enemy) -> void:
	enemy = enemy_
	var health = HealthComponent.get_or_die(enemy)
	health.health_updated.connect(_on_health_updated)
	# Set health to current value (in case we missed the signal setting initial health,
	# which happens when we play a level through F6). We only can do it if
	# we missed the signal, otherwise both updates happen in the same frame
	# and the progress bar seems confused.
	if health.health > 0:
		_set_health(health.health, health.max_health)
	var status = Component.get_status_component_or_die(enemy)
	status.statuses_changed.connect(_on_statuses_changed)
	var behavior = enemy.get_component_or_die(BehaviorComponent)
	behavior.behavior_updated.connect(_on_behavior_updated)
	# TODO: Make _on_behavior_updated return the full action instead of the name.
	# Not done yet as there are many tests, etc that use it so better to do it
	# in a standalone change.
	var action_name = ActionDef.NoAction
	if behavior.action:
		action_name = behavior.action.def.skill_name
	_on_behavior_updated(action_name, behavior.target)
	%Title.text = enemy.actor_name
	%HudStatusDisplay.clear()
	var effect_actuator_component = enemy.get_component_or_die(EffectActuatorComponent)
	effect_actuator_component.relics_changed.connect(_on_relics_changed)
	enemy.died.connect(_on_enemy_died)

func _on_enemy_died():
	%ActionLabel.text = "Dead"

func _set_health(health: int, max_health: int):
	%HealthBar.value = health
	%HealthBar.max_value = max_health
	%HealthLabel.text = "%d / %d" % [health, max_health]

func _on_health_updated(health_update: HealthComponent.HealthUpdate):
	_set_health(health_update.health, health_update.max_health)

func _on_statuses_changed(statuses: Array):
	%HudStatusDisplay.clear()
	for status_id in statuses:
		%HudStatusDisplay.add_status(status_id)

func _on_relics_changed(relics: Array[RelicDef]):
	%HudRelicDisplay.clear()
	for relic in relics:
		%HudRelicDisplay.add_relic(relic)

func _on_behavior_updated(action_name: StringName, _target: Target):
	# TODO: Do something with target, e.g. hovering could highlight the
	# target in the level. Or at least add target description.
	%ActionLabel.text = str(action_name) if action_name != ActionDef.NoAction else "Idle"

func _on_view_log_button_pressed():
	view_log_requested.emit(enemy)
