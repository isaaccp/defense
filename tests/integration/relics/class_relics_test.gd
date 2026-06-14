extends GutTest

const basic_test_level_scene = preload("res://tests/integration/actions/basic_test_level.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")

func _make_character_with_relic(relic_name: StringName) -> Level:
	var level: Level = basic_test_level_scene.instantiate()
	var gc: GameplayCharacter = test_character.duplicate(true)
	gc.relics = [relic_name]
	level.initialize([gc])
	add_child_autoqfree(level)
	await wait_frames(1)
	return level

func _focus(actor: Node) -> float:
	var vitals: VitalsComponent = Component.get_or_die(actor, VitalsComponent.component)
	return vitals.get_vital_current(VitalsComponent.VitalType.FOCUS)

func _drain_focus(actor: Node) -> void:
	var vitals: VitalsComponent = Component.get_or_die(actor, VitalsComponent.component)
	vitals.test_set_vital_current(VitalsComponent.VitalType.FOCUS, 0.0)

func _actuator(actor: Node) -> EffectActuatorComponent:
	var a: EffectActuatorComponent = Component.get_or_die(actor, EffectActuatorComponent.component)
	a.run()
	return a

func test_defiance_grants_focus_on_raw_damage():
	var level: Level = await _make_character_with_relic(&"Defiance")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	_drain_focus(actor)
	var hit_effect = HitEffect.new()
	hit_effect.damage = 5
	var logs: Array[String] = []
	var modified = actuator.modified_incoming_hit_effect(hit_effect, logs)
	assert_eq(_focus(actor), 5.0, "Should gain 5 focus from raw damage")

func test_unyielding_hope_grants_focus_on_missing_hp():
	var level: Level = await _make_character_with_relic(&"Unyielding Hope")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	_drain_focus(actor)
	var vitals: VitalsComponent = Component.get_or_die(actor, VitalsComponent.component)
	vitals.test_set_vital_current(VitalsComponent.VitalType.HEALTH, vitals.get_vital_max(VitalsComponent.VitalType.HEALTH) * 0.5)
	
	actuator._process(1.0)
	assert_gt(_focus(actor), 0.0, "Should gain focus when party has missing HP")

func test_killers_edge_grants_focus_on_kill():
	var level: Level = await _make_character_with_relic(&"Killer's Edge")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	_drain_focus(actor)
	actuator.notify_enemy_killed("TestVictim")
	assert_eq(_focus(actor), 2.0, "Should gain 2 focus per kill")

func test_killers_edge_grants_focus_on_wounded_enemy():
	var level: Level = await _make_character_with_relic(&"Killer's Edge")
	var actor: Node = level.characters.get_child(0)
	var target: Node = level.characters.get_child(0)
	var target_vitals: VitalsComponent = Component.get_or_die(target, VitalsComponent.component)
	target_vitals.test_set_vital_current(VitalsComponent.VitalType.HEALTH, target_vitals.get_vital_max(VitalsComponent.VitalType.HEALTH) * 0.4)
	
	var actuator: EffectActuatorComponent = _actuator(actor)
	_drain_focus(actor)
	var hit_effect = HitEffect.new()
	var logs: Array[String] = []
	var modified = actuator.modified_hit_effect(hit_effect, target, logs)
	assert_eq(_focus(actor), 0.5, "Should gain 0.5 focus when hitting enemy under 50% HP")

func test_meditation_grants_focus_when_idle():
	var level: Level = await _make_character_with_relic(&"Meditation")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	_drain_focus(actor)
	
	var behavior: BehaviorComponent = Component.get_or_die(actor, BehaviorComponent.component)
	behavior.rule = null
	
	actuator._process(1.0)
	assert_eq(_focus(actor), 1.0, "Should gain 1.0 focus per second when idle")
