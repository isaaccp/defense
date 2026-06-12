@tool
extends Object

class_name CharacterSceneManager

const character_scenes = {
	Enum.CharacterSceneId.KNIGHT: preload("res://character/knight/knight.tscn"),
	Enum.CharacterSceneId.WIZARD: preload("res://character/wizard/wizard.tscn"),
	Enum.CharacterSceneId.CLERIC: preload("res://character/cleric/cleric.tscn"),
	Enum.CharacterSceneId.ROGUE: preload("res://character/rogue/rogue.tscn"),
}

const relic_library = preload("res://effects/relics/relic_library.tres")

static func get_character_scene(scene_id: Enum.CharacterSceneId) -> PackedScene:
	assert(scene_id in character_scenes)
	return character_scenes[scene_id]

static func make(gameplay_character: GameplayCharacter) -> Character:
	var scene = CharacterSceneManager.get_character_scene(gameplay_character.scene_id)
	var character = scene.instantiate() as Character
	character.actor_name = gameplay_character.name

	var attributes_component = character.get_component_or_die(AttributesComponent)
	attributes_component.base_attributes = gameplay_character.attributes
	
	var behavior_component = Component.get_or_null(character, BehaviorComponent.component) as BehaviorComponent
	if behavior_component:
		behavior_component.stored_behavior = gameplay_character.behavior
		
	var effect_actuator = Component.get_or_null(character, EffectActuatorComponent.component) as EffectActuatorComponent
	if effect_actuator:
		effect_actuator.inject_relic_state(gameplay_character.relic_state.duplicate(true))
		for relic_name in gameplay_character.relics:
			var relic_def = relic_library.get_relic(relic_name)
			if relic_def:
				effect_actuator.add_relic(relic_def)
				
	# TODO: Can this just be removed or is it still needed with Vitalscomponent?
	# var health_component = HealthComponent.get_or_die(character)
	# health_component.initial_health = gameplay_character.health
	return character
