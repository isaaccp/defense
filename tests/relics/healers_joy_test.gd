extends GutTest

const basic_test_level_scene = preload("res://tests/actions/basic_test_level.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")

func _make_character_with_relic(relic_name: StringName) -> Level:
	var level: Level = basic_test_level_scene.instantiate()
	var gc: GameplayCharacter = test_character.duplicate(true)
	gc.relics = [relic_name]
	level.initialize([gc])
	add_child_autoqfree(level)
	# VitalsComponent._initialize() runs deferred.
	await wait_frames(1)
	return level

func _actuator(actor: Node) -> EffectActuatorComponent:
	var a: EffectActuatorComponent = Component.get_or_die(actor, EffectActuatorComponent.component)
	a.run()
	return a

func _vitals(actor: Node) -> VitalsComponent:
	return Component.get_or_die(actor, VitalsComponent.component)

func _attributes(actor: Node) -> AttributesComponent:
	return Component.get_or_die(actor, AttributesComponent.component)

func test_healers_joy_tracks_healing_and_increases_max_hp():
	var level: Level = await _make_character_with_relic(&"Healer's Joy")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	
	# Verify that we started with base health
	var base_hp: int = test_character.attributes.health
	var attribs: AttributesComponent = _attributes(actor)
	var vitals: VitalsComponent = _vitals(actor)
	
	assert_eq(attribs.health, base_hp, "Initial max HP should be base")
	assert_eq(vitals.get_vital_max(VitalsComponent.VitalType.HEALTH), float(base_hp), "Vitals max HP should be base")
	
	# Apply some healing that is under the threshold
	actuator.notify_heal_applied(40, "TestAlly")
	
	# Verify relic state is updated on the GameplayCharacter
	var gc: GameplayCharacter = actuator.persistent_game_state_component.state as GameplayCharacter
	var state = gc.relic_state.get(&"Healer's Joy", {})
	assert_eq(state.get("healed_so_far", 0), 40, "Total healed so far should be 40")
	
	# Verify HP hasn't increased yet (threshold is 100)
	assert_eq(attribs.health, base_hp, "HP should not increase before threshold")
	
	# Apply more healing to cross the 100 threshold (total 120)
	actuator.notify_heal_applied(80, "TestAlly")
	
	# Verify relic state updated
	assert_eq(state.get("healed_so_far", 0), 120, "Total healed so far should be 120")
	
	# Verify HP increased by 1 (120 / 100 = 1)
	assert_eq(attribs.health, base_hp + 1, "Max HP should increase by 1")
	assert_eq(vitals.get_vital_max(VitalsComponent.VitalType.HEALTH), float(base_hp + 1), "Vitals max HP should update dynamically to base+1")
