@tool
extends Node

class_name EffectActuatorComponent

const component = &"EffectActuatorComponent"

@export_group("Required")
@export var status_component: StatusComponent



signal able_to_act_changed(can_act: bool)
signal attribute_effects_changed
signal relics_changed(relics: Array[RelicDef])


# TODO: Move to a single place if https://github.com/godotengine/godot-proposals/issues/6416 is implemented.
var running = false

var effect_by_name: Dictionary[StringName, EffectDef] = {}
var effect_script_by_name: Dictionary[StringName, Effect] = {}
var effect_script_by_effect_type: Dictionary[int, Array] = {}
var relics: Array[RelicDef]

var local_relic_state: Dictionary[StringName, Dictionary] = {}

func inject_relic_state(state: Dictionary[StringName, Dictionary]):
	local_relic_state = state.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)

func extract_relic_state() -> Dictionary[StringName, Dictionary]:
	return local_relic_state.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)

var unable_to_act_count = 0:
	set(value):
		if unable_to_act_count == 0 and value > 0:
			able_to_act_changed.emit(false)
		elif unable_to_act_count > 0 and value == 0:
			able_to_act_changed.emit(true)
		unable_to_act_count = value

func _ready():
	if Engine.is_editor_hint():
		return

func run():
	if running:
		push_error("run() called twice on %s" % component)
		return
	running = true
	status_component.status_added.connect(_on_status_added)
	status_component.status_removed.connect(_on_status_removed)

func stop():
	running = false
	status_component.status_added.disconnect(_on_status_added)
	status_component.status_removed.disconnect(_on_status_removed)

func add_relic(relic: RelicDef):
	relics.append(relic)
	_add_effect(relic, null)
	relics_changed.emit(relics)

func modified_attributes(base_attributes: Attributes) -> Attributes:
	var attributes = base_attributes.duplicate(true)
	for effect_script in effect_script_by_effect_type.get(EffectDef.EffectType.ATTRIBUTE, []):
		effect_script.modify_attributes(attributes)
	return attributes

# logger takes a String as parameter. target is the actor being hit (may be null
# for callers that don't have target context — relics requiring it should guard).
func modified_hit_effect(base_hit_effect: HitEffect, target: Node, effect_log: Array[String]) -> HitEffect:
	var hit_effect = base_hit_effect.duplicate(true)
	var logger = func(text: String): effect_log.append(text)
	for effect_script in effect_script_by_effect_type.get(EffectDef.EffectType.HIT_EFFECT, []):
		effect_script.modify_hit_effect(hit_effect, target, logger)
	return hit_effect

# Log is an empty array in which to log messages from each effect that modifies the cooldown.
func modified_cooldown(action: ActionDef, cooldown: float, effect_log: Array[String]) -> float:
	var effective_cooldown = cooldown
	var logger = func(text: String): effect_log.append(text)
	for effect_script in effect_script_by_effect_type.get(EffectDef.EffectType.ACTION_COOLDOWN, []):
		effective_cooldown = effect_script.modified_action_cooldown(action, effective_cooldown, logger)
	return effective_cooldown

## Dispatch hooks for event-triggered effects (relics, status effects that react to events).
## Components call these from the relevant trigger sites.
func notify_damage_taken(damage_taken: int, attacker_name: String) -> void:
	for effect_script in effect_script_by_effect_type.get(EffectDef.EffectType.ON_DAMAGE_TAKEN, []):
		effect_script.on_damage_taken(damage_taken, attacker_name)

func notify_heal_applied(amount_healed: int, target_name: String) -> void:
	for effect_script in effect_script_by_effect_type.get(EffectDef.EffectType.ON_HEAL_APPLIED, []):
		effect_script.on_heal_applied(amount_healed, target_name)

func notify_enemy_killed(victim_name: String) -> void:
	for effect_script in effect_script_by_effect_type.get(EffectDef.EffectType.ON_ENEMY_KILLED, []):
		effect_script.on_enemy_killed(victim_name)

func _on_status_added(status: StatusDef, status_params: EffectParams):
	_add_effect(status, status_params)

func _on_status_removed(status_name: StringName):
	_remove_effect(status_name)

func _add_effect(effect: EffectDef, effect_params: EffectParams):
	effect_by_name[effect.name] = effect
	var script = effect.effect_script.new() as Effect
	script.bearer = get_parent()
	script.effect_name = effect.name
	if not local_relic_state.has(effect.name):
		local_relic_state[effect.name] = {}
	script.persistent_state = local_relic_state[effect.name]
	script.initialize(effect_params)
	effect_script_by_name[effect.name] = script
	# Some effect types may not require tracking like this, but unless it
	# becomes a problem it's probably fine to track anyway.
	for effect_type in effect.effect_types:
		if not effect_type in effect_script_by_effect_type:
			effect_script_by_effect_type[effect_type] = []
		effect_script_by_effect_type[effect_type].append(script)
		match effect_type:
			EffectDef.EffectType.ABLE_TO_ACT:
				script.able_to_act.connect(_on_able_to_act_changed)
			EffectDef.EffectType.ATTRIBUTE:
				attribute_effects_changed.emit()
	script.on_effect_added()

func _remove_effect(effect_name: StringName):
	var script = effect_script_by_name[effect_name] as Effect
	script.on_effect_removed()
	effect_script_by_name.erase(effect_name)
	var effect = effect_by_name[effect_name] as EffectDef
	for effect_type in effect.effect_types:
		effect_script_by_effect_type[effect_type].erase(script)
		match effect_type:
			EffectDef.EffectType.ATTRIBUTE:
				attribute_effects_changed.emit()
	effect_by_name.erase(effect_name)

func _on_able_to_act_changed(can_act: bool):
	if can_act:
		unable_to_act_count -= 1
	else:
		unable_to_act_count += 1

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	if not status_component:
		warnings.append("Must set status_component")
	return warnings
