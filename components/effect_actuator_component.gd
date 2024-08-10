@tool
extends Node

class_name EffectActuatorComponent

const component = &"EffectActuatorComponent"

@export_group("Required")
@export var status_component: StatusComponent

@export_group("Optional")
# Should be set for characters for relic management. If we want enemies to have relics in the
# future the best option would likely be to have a RelicComponent that manages relics
# and can rely on persistent GameplayCharacter for characters and manage the relics
# itself for enemies.
@export var persistent_game_state_component: PersistentGameStateComponent

signal able_to_act_changed(can_act: bool)
signal attribute_effects_changed
signal relics_changed(relics: Array[RelicDef])

const relic_library = preload("res://effects/relics/relic_library.tres")

# TODO: Move to a single place if https://github.com/godotengine/godot-proposals/issues/6416 is implemented.
var running = false

var effect_by_name: Dictionary
var effect_script_by_name: Dictionary
var effect_script_by_effect_type: Dictionary
var gameplay_character: GameplayCharacter
var relics: Array[RelicDef]

var unable_to_act_count = 0:
	set(value):
		if unable_to_act_count == 0 and value > 0:
			able_to_act_changed.emit(false)
		elif unable_to_act_count > 0 and value == 0:
			able_to_act_changed.emit(true)
		unable_to_act_count = value

func run():
	if running:
		assert(false, "run() called twice on %s" % component)
	running = true
	if persistent_game_state_component:
		gameplay_character = persistent_game_state_component.state
		for relic_name in gameplay_character.relics:
			load_relic(relic_name)
	status_component.status_added.connect(_on_status_added)
	status_component.status_removed.connect(_on_status_removed)

func load_relic(relic_name: StringName):
	var relic = relic_library.get_relic(relic_name)
	relics.append(relic)
	_add_effect(relic)
	relics_changed.emit(relics)

func add_relic(relic_name: StringName):
	load_relic(relic_name)
	if gameplay_character:
		gameplay_character.add_relic(relic_name)

func modified_attributes(base_attributes: Attributes) -> Attributes:
	var attributes = base_attributes.duplicate(true)
	for effect_script in effect_script_by_effect_type.get(EffectDef.EffectType.ATTRIBUTE, []):
		effect_script.modify_attributes(attributes)
	return attributes

func modified_hit_effect(base_hit_effect: HitEffect) -> HitEffect:
	var hit_effect = base_hit_effect.duplicate(true)
	for effect_script in effect_script_by_effect_type.get(EffectDef.EffectType.HIT_EFFECT, []):
		effect_script.modify_hit_effect(hit_effect)
	return hit_effect

func _on_status_added(status: StatusDef):
	_add_effect(status)

func _on_status_removed(status_name: StringName):
	_remove_effect(status_name)

func _add_effect(effect: EffectDef):
	effect_by_name[effect.name] = effect
	var script = effect.effect_script.new() as Effect
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
