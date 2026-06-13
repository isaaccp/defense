@tool
extends Node

class_name DamageComponent

const component: StringName = &"DamageComponent"

signal hit(hit_effect: HitEffect)


@export_group("Required")
@export var attributes_component: AttributesComponent
@export var vitals_component: VitalsComponent

@export_group("Optional")
@export var logging_component: LoggingComponent
@export var effect_actuator_component: EffectActuatorComponent

var running = false

func _ready():
	if Engine.is_editor_hint():
		return

func run():
	running = true

func stop():
	running = false

# Returns true if hit caused any damage.
func process_hit(hit_effect: HitEffect) -> HitResult:
	hit.emit(hit_effect)
	if not running:
		# Hit arrived after the component was stopped (e.g. level ended in the
		# same physics frame as an in-flight enemy melee). Return a no-op
		# result rather than null so callers don't have to special-case shutdown.
		return HitResult.new()
	var hit_result = HitResult.new()
	var effect_log: Array[String] = []
	var effective_hit_effect = hit_effect
	if effect_actuator_component:
		effective_hit_effect = effect_actuator_component.modified_incoming_hit_effect(hit_effect, effect_log)
		for log_entry in effect_log:
			_log(log_entry)

	var adjusted_damage = effective_hit_effect.adjusted_damage()
	# Check if it's a heal.
	if adjusted_damage < 0:
		vitals_component.apply_vital_change(VitalsComponent.VitalType.HEALTH, -adjusted_damage, true)
		hit_result.damage = adjusted_damage
		return hit_result
	var damage_str = "Incoming Damage: %s\n" % adjusted_damage
	# If damage was 0 to begin with, just return.
	if adjusted_damage == 0:
		return hit_result
	var after_armor_damage = adjusted_damage
	if effective_hit_effect.damage_type.macro_type == DamageType.MacroType.PHYSICAL:
		if attributes_component.armor > 0:
			var armor_str = "Base Armor: %d\n" % attributes_component.armor
			var effective_armor = float(attributes_component.armor)
			var effective_armor_str = "Effective Armor: %d (base armor)" % attributes_component.armor
			if effective_hit_effect.fraction_armor_pen > 0:
				var fraction_armor_pen_reduction = effective_armor * effective_hit_effect.fraction_armor_pen
				if fraction_armor_pen_reduction > 0:
					effective_armor_str += " - %0.2f (%%-age armor pen)" % fraction_armor_pen_reduction
					effective_armor -= fraction_armor_pen_reduction
			if effective_hit_effect.flat_armor_pen > 0:
				effective_armor_str += " - %d (flat armor pen)" % effective_hit_effect.flat_armor_pen
				effective_armor -= effective_hit_effect.flat_armor_pen
				if effective_armor < 0:
					effective_armor = 0
			effective_armor = round(effective_armor)
			effective_armor_str += " = %d (effective armor)" % effective_armor
			if attributes_component.armor != effective_armor:
				armor_str += "%s\n" % effective_armor_str
			after_armor_damage = max(0, adjusted_damage - effective_armor)
			damage_str += "%s" % armor_str
			if after_armor_damage != adjusted_damage:
				damage_str += "After Armor Damage: %d - %d (armor) = %d\n" % [adjusted_damage, effective_armor, after_armor_damage]
		if after_armor_damage <= 0:
			_log_blocked_damage(damage_str)
			return hit_result
	var resistance_multiplier = attributes_component.resistance_multiplier_for(effective_hit_effect.attack_type, effective_hit_effect.damage_type)
	var after_resistance_damage = round(after_armor_damage * resistance_multiplier)
	if after_resistance_damage != after_armor_damage:
		damage_str += "Resistance multiplier (%s, %s): %0.1f" % [effective_hit_effect.attack_type.name, effective_hit_effect.damage_type.name, resistance_multiplier]
		damage_str += "After Resistance Damage: %d * %0.1f = %d" % [after_armor_damage, resistance_multiplier, after_resistance_damage]
	if after_resistance_damage <= 0:
		_log_blocked_damage(damage_str)
		return hit_result
	vitals_component.apply_vital_change(VitalsComponent.VitalType.HEALTH, -after_resistance_damage, true)
	_log_damage(damage_str)
	hit_result.damage = after_resistance_damage
	var actor = get_parent()
	hit_result.destroyed = actor.destroyed
	return hit_result

func _log_damage(damage_details: String):
	_log("damage inflicted", damage_details)

func _log_blocked_damage(damage_details: String):
	_log("damage blocked", damage_details)

func _log(message: String, tooltip: String = ""):
	if not logging_component:
		return
	logging_component.add_log_entry(LoggingComponent.LogType.DAMAGE, message, tooltip)
