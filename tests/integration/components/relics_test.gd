extends GutTest

const status_component_scene = preload("res://components/status_component.tscn")
const effect_actuator_component_scene = preload("res://components/effect_actuator_component.tscn")
const attributes_component_scene = preload("res://components/attributes_component.tscn")
const vitals_component_scene = preload("res://components/vitals_component.tscn")
const damage_component_scene = preload("res://components/damage_component.tscn")
const behavior_component_scene = preload("res://components/behavior_component.tscn")

var unit: Actor
var status_component: StatusComponent
var effect_actuator_component: EffectActuatorComponent
var attributes_component: AttributesComponent
var vitals_component: VitalsComponent
var damage_component: DamageComponent
var behavior_component: BehaviorComponent

func before_each():
	unit = Actor.new()
	unit.name = "TestUnit"
	
	status_component = status_component_scene.instantiate()
	status_component.name = "StatusComponent"
	
	effect_actuator_component = effect_actuator_component_scene.instantiate()
	effect_actuator_component.name = "EffectActuatorComponent"
	effect_actuator_component.status_component = status_component
	
	attributes_component = attributes_component_scene.instantiate()
	attributes_component.name = "AttributesComponent"
	attributes_component.effect_actuator_component = effect_actuator_component
	attributes_component.base_attributes = Attributes.new()
	attributes_component.base_attributes.health = 100
	attributes_component.base_attributes.speed = 100
	attributes_component.base_attributes.focus = 100
	
	vitals_component = vitals_component_scene.instantiate()
	vitals_component.name = "VitalsComponent"
	vitals_component.attributes_component = attributes_component
	
	damage_component = damage_component_scene.instantiate()
	damage_component.name = "DamageComponent"
	damage_component.vitals_component = vitals_component
	damage_component.attributes_component = attributes_component
	
	effect_actuator_component.name = "EffectActuatorComponent"
	effect_actuator_component.status_component = status_component
	
	behavior_component = behavior_component_scene.instantiate()
	behavior_component.name = "BehaviorComponent"
	behavior_component.effect_actuator_component = effect_actuator_component
	
	attributes_component.effect_actuator_component = effect_actuator_component
	damage_component.effect_actuator_component = effect_actuator_component
	
	unit.add_child(attributes_component)
	unit.add_child(vitals_component)
	unit.add_child(damage_component)
	unit.add_child(status_component)
	unit.add_child(effect_actuator_component)
	unit.add_child(behavior_component)
	
	add_child_autoqfree(unit)
	
	await get_tree().process_frame
	vitals_component.test_set_vital_current(VitalsComponent.VitalType.FOCUS, 0)
	
	unit.run()

func test_arcane_battery_relic():
	var relic = preload("res://effects/relics/arcane_battery.tres")
	effect_actuator_component.add_relic(relic)
	var mod_attrs = effect_actuator_component.modified_attributes(attributes_component.base_attributes)
	assert_eq(int(mod_attrs.focus), 130)

func test_arcane_conduit_relic():
	var relic = preload("res://effects/relics/arcane_conduit.tres")
	effect_actuator_component.add_relic(relic)
	var he = HitEffect.new()
	he.damage = 100
	he.damage_type = preload("res://game_logic/damage_types/arcane.tres")
	var dummy_arr: Array[String] = []
	he = effect_actuator_component.modified_hit_effect(he, null, dummy_arr)
	assert_eq(he.damage_multiplier, 1.1)

func test_berserkers_mark_relic():
	var relic = preload("res://effects/relics/berserkers_mark.tres")
	effect_actuator_component.add_relic(relic)
	vitals_component.test_set_vital_current(VitalsComponent.VitalType.HEALTH, 50)
	var he = HitEffect.new()
	he.damage = 100
	var dummy_arr: Array[String] = []
	he = effect_actuator_component.modified_hit_effect(he, null, dummy_arr)
	assert_eq(he.damage_multiplier, 1.25)

func test_blood_frenzy_relic():
	var relic = preload("res://effects/relics/blood_frenzy.tres")
	effect_actuator_component.add_relic(relic)
	var test_action = preload("res://skill_tree/actions/sword_attack.tres")
	behavior_component.action_cooldowns[test_action.name] = 5.0
	effect_actuator_component.notify_damage_taken(10, "attacker")
	assert_eq(behavior_component.action_cooldowns[test_action.name], 4.5)

func test_bracelet_of_focus_relic():
	var relic = preload("res://effects/relics/bracelet_of_focus.tres")
	effect_actuator_component.add_relic(relic)
	var dummy_arr: Array[String] = []
	var result = effect_actuator_component.modified_cooldown(ActionDef.new(), 10.0, dummy_arr)
	assert_eq(result, 7.0)

func test_collector_relic():
	var relic = preload("res://effects/relics/collector.tres")
	var dummy1 = preload("res://effects/relics/arcane_battery.tres")
	var dummy2 = preload("res://effects/relics/arcane_conduit.tres")
	effect_actuator_component.add_relic(relic)
	effect_actuator_component.add_relic(dummy1)
	effect_actuator_component.add_relic(dummy2)
	var he = HitEffect.new()
	he.damage = 100
	var dummy_arr: Array[String] = []
	he = effect_actuator_component.modified_hit_effect(he, null, dummy_arr)
	assert_eq(he.damage_multiplier, 1.02)

func test_defiance_relic():
	var relic = preload("res://effects/relics/defiance.tres")
	effect_actuator_component.add_relic(relic)
	var he = HitEffect.new()
	he.damage = 10
	var dummy_arr: Array[String] = []
	he = effect_actuator_component.modified_incoming_hit_effect(he, dummy_arr)
	assert_eq(int(vitals_component.get_vital_current(VitalsComponent.VitalType.FOCUS)), 10)

func test_echoing_ward_relic():
	var relic = preload("res://effects/relics/echoing_ward.tres")
	effect_actuator_component.add_relic(relic)
	var st = StatusDef.new()
	st.status_type = StatusDef.StatusType.WARD
	var dur = effect_actuator_component.modified_incoming_status_duration(st, 10.0)
	assert_eq(dur, 15.0)

func test_ember_brand_relic():
	var relic = preload("res://effects/relics/ember_brand.tres")
	effect_actuator_component.add_relic(relic)
	var he = HitEffect.new()
	var action_def = preload("res://skill_tree/actions/sword_attack.tres")
	he.action_name = action_def.skill_name
	var dummy_arr: Array[String] = []
	he = effect_actuator_component.modified_hit_effect(he, null, dummy_arr)
	var expected_type = preload("res://game_logic/damage_types/fire.tres")
	assert_eq(he.damage_type, expected_type)

func test_executioners_axe_relic():
	var relic = preload("res://effects/relics/executioners_axe.tres")
	effect_actuator_component.add_relic(relic)
	var target = Actor.new()
	target.name = "TargetUnit"
	var t_attr = attributes_component_scene.instantiate()
	t_attr.base_attributes = Attributes.new()
	t_attr.base_attributes.health = 100
	var t_vitals = vitals_component_scene.instantiate()
	t_vitals.attributes_component = t_attr
	target.add_child(t_attr)
	target.add_child(t_vitals)
	add_child_autoqfree(target)
	t_vitals._initialize()
	t_vitals.run()
	t_vitals.test_set_vital_current(VitalsComponent.VitalType.HEALTH, 20)
	var he = HitEffect.new()
	he.damage = 10
	var dummy_arr: Array[String] = []
	he = effect_actuator_component.modified_hit_effect(he, target, dummy_arr)
	assert_eq(he.damage_multiplier, 1.5)

func test_focused_mind_relic():
	var relic = preload("res://effects/relics/focused_mind.tres")
	effect_actuator_component.add_relic(relic)
	vitals_component.test_set_vital_current(VitalsComponent.VitalType.FOCUS, 80)
	var he = HitEffect.new()
	he.damage = 100
	var dummy_arr: Array[String] = []
	he = effect_actuator_component.modified_incoming_hit_effect(he, dummy_arr)
	assert_eq(he.damage_multiplier, 0.75)

func test_giants_belt_relic():
	var relic = preload("res://effects/relics/giants_belt.tres")
	effect_actuator_component.add_relic(relic)
	var mod_attrs = effect_actuator_component.modified_attributes(attributes_component.base_attributes)
	assert_eq(int(mod_attrs.health), 130)
	assert_eq(int(mod_attrs.speed), 85)

func test_hallowed_vestments_relic():
	var relic = preload("res://effects/relics/hallowed_vestments.tres")
	effect_actuator_component.add_relic(relic)
	var mod_attrs = effect_actuator_component.modified_attributes(attributes_component.base_attributes)
	var ranged_type = preload("res://game_logic/attack_types/ranged.tres")
	assert_eq(mod_attrs.resistance[0].attack_type, ranged_type)

func test_healers_joy_relic():
	var relic = preload("res://effects/relics/healers_joy.tres")
	effect_actuator_component.add_relic(relic)
	effect_actuator_component.notify_heal_applied(150, "Ally")
	var mod_attrs = effect_actuator_component.modified_attributes(attributes_component.base_attributes)
	assert_eq(int(mod_attrs.health), 101)

func test_igniter_quiver_relic():
	var relic = preload("res://effects/relics/igniter_quiver.tres")
	effect_actuator_component.add_relic(relic)
	var he = HitEffect.new()
	var action_def = preload("res://skill_tree/actions/bow_attack.tres")
	he.action_name = action_def.skill_name
	var dummy_arr: Array[String] = []
	he = effect_actuator_component.modified_hit_effect(he, null, dummy_arr)
	var expected_type = preload("res://game_logic/damage_types/fire.tres")
	assert_eq(he.damage_type, expected_type)

func test_killers_edge_relic():
	var relic = preload("res://effects/relics/killers_edge.tres")
	effect_actuator_component.add_relic(relic)
	effect_actuator_component.notify_enemy_killed("Enemy")
	assert_eq(int(vitals_component.get_vital_current(VitalsComponent.VitalType.FOCUS)), 2)

func test_killers_insight_relic():
	var relic = preload("res://effects/relics/killers_insight.tres")
	effect_actuator_component.add_relic(relic)
	var target = Actor.new()
	target.name = "TargetUnit"
	var t_attr = attributes_component_scene.instantiate()
	t_attr.base_attributes = Attributes.new()
	t_attr.base_attributes.health = 100
	var t_vitals = vitals_component_scene.instantiate()
	t_vitals.attributes_component = t_attr
	target.add_child(t_attr)
	target.add_child(t_vitals)
	add_child_autoqfree(target)
	t_vitals._initialize()
	t_vitals.run()
	t_vitals.test_set_vital_current(VitalsComponent.VitalType.HEALTH, 20)
	var he = HitEffect.new()
	var dummy_arr: Array[String] = []
	he = effect_actuator_component.modified_hit_effect(he, target, dummy_arr)
	assert_eq(he.damage_multiplier, 1.5)

func test_meditation_relic():
	var relic = preload("res://effects/relics/meditation.tres")
	effect_actuator_component.add_relic(relic)
	behavior_component.rule = null
	effect_actuator_component._process(1.0)
	assert_eq(int(vitals_component.get_vital_current(VitalsComponent.VitalType.FOCUS)), 1)

func test_momentum_crystal_relic():
	var relic = preload("res://effects/relics/momentum_crystal.tres")
	effect_actuator_component.add_relic(relic)
	effect_actuator_component.notify_enemy_killed("Enemy")
	var status_def = preload("res://effects/statuses/swiftness.tres")
	assert_true(status_component.has_status(status_def.name))

func test_opportunist_relic():
	var relic = preload("res://effects/relics/opportunist.tres")
	effect_actuator_component.add_relic(relic)
	var target = Actor.new()
	target.name = "TargetUnit"
	var t_attr = attributes_component_scene.instantiate()
	t_attr.base_attributes = Attributes.new()
	t_attr.base_attributes.health = 100
	var t_vitals = vitals_component_scene.instantiate()
	t_vitals.attributes_component = t_attr
	target.add_child(t_attr)
	target.add_child(t_vitals)
	add_child_autoqfree(target)
	t_vitals._initialize()
	t_vitals.run()
	t_vitals.test_set_vital_current(VitalsComponent.VitalType.HEALTH, 30)
	var he = HitEffect.new()
	he.damage = 10
	var dummy_arr: Array[String] = []
	he = effect_actuator_component.modified_hit_effect(he, target, dummy_arr)
	assert_eq(he.damage_multiplier, 1.25)

func test_overflowing_chalice_relic():
	var relic = preload("res://effects/relics/overflowing_chalice.tres")
	effect_actuator_component.add_relic(relic)
	vitals_component.test_set_vital_current(VitalsComponent.VitalType.HEALTH, 50)
	effect_actuator_component.notify_heal_applied(20, "Ally")
	assert_eq(int(vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH)), 60)

func test_pyromancers_mark_relic():
	var relic = preload("res://effects/relics/pyromancers_mark.tres")
	effect_actuator_component.add_relic(relic)
	var he = HitEffect.new()
	he.damage = 10
	he.damage_type = preload("res://game_logic/damage_types/fire.tres")
	var dummy_arr: Array[String] = []
	he = effect_actuator_component.modified_hit_effect(he, null, dummy_arr)
	assert_eq(he.damage_multiplier, 1.3)

func test_reagent_pouch_relic():
	var relic = preload("res://effects/relics/reagent_pouch.tres")
	effect_actuator_component.add_relic(relic)
	var mod_attrs = effect_actuator_component.modified_attributes(attributes_component.base_attributes)
	assert_eq(mod_attrs.focus_regen, 0.5)

func test_regeneration_ring_relic():
	var relic = preload("res://effects/relics/regeneration_ring.tres")
	effect_actuator_component.add_relic(relic)
	var mod_attrs = effect_actuator_component.modified_attributes(attributes_component.base_attributes)
	assert_eq(mod_attrs.health_regen, 1.0)

func test_second_wind_relic():
	var relic = preload("res://effects/relics/second_wind.tres")
	effect_actuator_component.add_relic(relic)
	vitals_component.test_set_vital_current(VitalsComponent.VitalType.HEALTH, 50)
	effect_actuator_component.notify_damage_taken(25, "Enemy") # Drops below 30 (to 25), heals to 50
	assert_eq(int(vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH)), 50)

func test_spiked_pauldrons_relic():
	var relic = preload("res://effects/relics/spiked_pauldrons.tres")
	effect_actuator_component.add_relic(relic)
	
	var enemy = Actor.new()
	enemy.add_to_group("enemies")
	enemy.actor_name = "Enemy"
	var t_attr = attributes_component_scene.instantiate()
	t_attr.base_attributes = Attributes.new()
	t_attr.base_attributes.health = 100
	var t_vitals = vitals_component_scene.instantiate()
	t_vitals.attributes_component = t_attr
	enemy.add_child(t_attr)
	enemy.add_child(t_vitals)
	add_child_autoqfree(enemy)
	t_vitals._initialize()
	t_vitals.run()
	
	effect_actuator_component.notify_damage_taken(10, "Enemy")
	assert_eq(int(t_vitals.get_vital_current(VitalsComponent.VitalType.HEALTH)), 98)
	
	enemy.queue_free()

func test_unyielding_hope_relic():
	var relic = preload("res://effects/relics/unyielding_hope.tres")
	effect_actuator_component.add_relic(relic)
	
	var SideC = preload("res://components/side_component.tscn")
	var side = SideC.instantiate()
	side.side = 1
	unit.add_child(side)
	
	var ally = Actor.new()
	ally.add_to_group("characters")
	var a_side = SideC.instantiate()
	a_side.side = 1 # Player side
	ally.add_child(a_side)
	var a_attr = attributes_component_scene.instantiate()
	a_attr.base_attributes = Attributes.new()
	a_attr.base_attributes.health = 100
	var a_vitals = vitals_component_scene.instantiate()
	a_vitals.attributes_component = a_attr
	ally.add_child(a_attr)
	ally.add_child(a_vitals)
	add_child_autoqfree(ally)
	a_vitals._initialize()
	a_vitals.run()
	a_vitals.test_set_vital_current(VitalsComponent.VitalType.HEALTH, 50) # 50% missing
	effect_actuator_component._process(1.0)
	
	assert_eq(int(vitals_component.get_vital_current(VitalsComponent.VitalType.FOCUS)), 1)
	
	ally.queue_free()

func test_vampires_tooth_relic():
	var relic = preload("res://effects/relics/vampires_tooth.tres")
	effect_actuator_component.add_relic(relic)
	vitals_component.test_set_vital_current(VitalsComponent.VitalType.HEALTH, 50)
	effect_actuator_component.notify_enemy_killed("Enemy")
	assert_eq(int(vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH)), 51)

func test_vorpal_blade_relic():
	var relic = preload("res://effects/relics/vorpal_blade.tres")
	effect_actuator_component.add_relic(relic)
	var he = HitEffect.new()
	he.damage_type = preload("res://game_logic/damage_types/slashing.tres")
	var dummy_arr: Array[String] = []
	he = effect_actuator_component.modified_hit_effect(he, null, dummy_arr)
	assert_eq(he.flat_armor_pen, 1)

