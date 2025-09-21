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
		print("Ignoring hit received while not running")
		return
	var hit_result = HitResult.new()
	var adjusted_damage = hit_effect.adjusted_damage()
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
	if hit_effect.damage_type.macro_type == DamageType.MacroType.PHYSICAL:
		if attributes_component.armor > 0:
			var armor_str = "Base Armor: %d\n" % attributes_component.armor
			var effective_armor = float(attributes_component.armor)
			var effective_armor_str = "Effective Armor: %d (base armor)" % attributes_component.armor
			if hit_effect.fraction_armor_pen > 0:
				var fraction_armor_pen_reduction = effective_armor * hit_effect.fraction_armor_pen
				if fraction_armor_pen_reduction > 0:
					effective_armor_str += " - %0.2f (%%-age armor pen)" % fraction_armor_pen_reduction
					effective_armor -= fraction_armor_pen_reduction
			if hit_effect.flat_armor_pen > 0:
				effective_armor_str += " - %d (flat armor pen)" % hit_effect.flat_armor_pen
				effective_armor -= hit_effect.flat_armor_pen
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
	var resistance_multiplier = attributes_component.resistance_multiplier_for(hit_effect.attack_type, hit_effect.damage_type)
	var after_resistance_damage = round(after_armor_damage * resistance_multiplier)
	if after_resistance_damage != after_armor_damage:
		damage_str += "Resistance multiplier (%s, %s): %0.1f" % [hit_effect.attack_type.name, hit_effect.damage_type.name, resistance_multiplier]
		damage_str += "After Resistance Damage: %d * %0.1f = %d" % [after_armor_damage, resistance_multiplier, after_resistance_damage]
	if after_resistance_damage <= 0:
		_log_blocked_damage(damage_str)
		return hit_result
	vitals_component.apply_vital_change(VitalsComponent.VitalType.HEALTH, -after_resistance_damage, true)
	_log_damage(damage_str)
	hit_result.damage = after_resistance_damage
	# In test cases, actor may be unset. TODO: Consider if we want to just create a new "lifecycle"
	# component or similar to handle this.
	if get_parent() is Actor:
		hit_result.destroyed = get_parent().destroyed
	else:
		hit_result.destroyed = false
	return hit_result

func _log_damage(damage_details: String):
	_log("damage inflicted", damage_details)

func _log_blocked_damage(damage_details: String):
	_log("damage blocked", damage_details)

func _log(message: String, tooltip: String = ""):
	if not logging_component:
		return
	logging_component.add_log_entry(LoggingComponent.LogType.DAMAGE, message, tooltip)
