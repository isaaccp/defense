extends GutTest

# Tests for the 4 class relics (focus-management identity relics) and the
# EffectActuator dispatch methods that fire them.

const basic_test_level_scene = preload("res://tests/integration/actions/basic_test_level.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")

func _make_character_with_relic(relic_name: StringName) -> Level:
	var level: Level = basic_test_level_scene.instantiate()
	var gc: GameplayCharacter = test_character.duplicate(true)
	gc.relics = [relic_name]
	level.initialize([gc])
	add_child_autoqfree(level)
	# VitalsComponent._initialize() runs deferred, so wait a frame so FOCUS
	# is registered before tests poke at it.
	await wait_frames(1)
	return level

func _focus(actor: Node) -> float:
	var vitals: VitalsComponent = Component.get_or_die(actor, VitalsComponent.component)
	return vitals.get_vital_current(VitalsComponent.VitalType.FOCUS)

# Drain to 0 so gain-tests aren't clamped by max focus.
func _drain_focus(actor: Node) -> void:
	var vitals: VitalsComponent = Component.get_or_die(actor, VitalsComponent.component)
	vitals.test_set_vital_current(VitalsComponent.VitalType.FOCUS, 0.0)

func _actuator(actor: Node) -> EffectActuatorComponent:
	var a: EffectActuatorComponent = Component.get_or_die(actor, EffectActuatorComponent.component)
	a.run()  # loads relics from the GameplayCharacter
	return a

# --- Battle Fury (ON_DAMAGE_TAKEN: +1 focus per HP taken) ---

func test_battle_fury_grants_focus_on_damage_taken():
	var level: Level = await _make_character_with_relic(&"Battle Fury")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	_drain_focus(actor)
	actuator.notify_damage_taken(5, "TestAttacker")
	assert_eq(_focus(actor), 5.0, "Should gain 5 focus from 5 damage taken")

func test_battle_fury_caps_at_max_focus():
	var level: Level = await _make_character_with_relic(&"Battle Fury")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	var vitals: VitalsComponent = Component.get_or_die(actor, VitalsComponent.component)
	var max_focus: float = vitals.get_vital_max(VitalsComponent.VitalType.FOCUS)
	actuator.notify_damage_taken(int(max_focus + 100), "TestAttacker")
	assert_eq(_focus(actor), max_focus, "Should cap at max focus")

# --- Channeling (ON_HEAL_APPLIED: +50% of HP healed → focus) ---

func test_channeling_grants_focus_on_heal():
	var level: Level = await _make_character_with_relic(&"Channeling")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	_drain_focus(actor)
	actuator.notify_heal_applied(10, "TestAlly")
	assert_eq(_focus(actor), 5.0, "Should gain 5 focus from healing 10 HP")

# --- Killer's Edge (ON_ENEMY_KILLED: +2 focus flat) ---

func test_killers_edge_grants_focus_on_kill():
	var level: Level = await _make_character_with_relic(&"Killer's Edge")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	_drain_focus(actor)
	actuator.notify_enemy_killed("TestVictim")
	assert_eq(_focus(actor), 2.0, "Should gain 2 focus per kill")

# --- Arcane Focus (ATTRIBUTE: +1.0/s focus_regen) ---

func test_arcane_focus_boosts_focus_regen():
	var level: Level = await _make_character_with_relic(&"Arcane Focus")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	var base: float = test_character.attributes.focus_regen
	var modified: Attributes = actuator.modified_attributes(test_character.attributes)
	assert_eq(modified.focus_regen, base + 1.0, "Focus regen should be base +1.0/s")

# --- Dispatch sanity: notify_* methods only fire effects with matching type ---

func test_battle_fury_doesnt_fire_on_heal():
	# Battle Fury has effect_type ON_DAMAGE_TAKEN; notify_heal_applied should not grant focus.
	var level: Level = await _make_character_with_relic(&"Battle Fury")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	var starting_focus: float = _focus(actor)
	actuator.notify_heal_applied(99, "TestAlly")
	assert_eq(_focus(actor), starting_focus, "Heal should not grant Battle Fury focus")

func test_channeling_doesnt_fire_on_kill():
	var level: Level = await _make_character_with_relic(&"Channeling")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	var starting_focus: float = _focus(actor)
	actuator.notify_enemy_killed("TestVictim")
	assert_eq(_focus(actor), starting_focus, "Kill should not grant Channeling focus")
