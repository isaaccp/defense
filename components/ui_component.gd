@tool
extends Node2D

class_name UIComponent

const component: StringName = &"UIComponent"

@export_group("Required")
@export var vitals_component: VitalsComponent

var running = false

var config: Array[Dictionary]

func _ready():
	config = [
		{ 'bar': %HealthBar, 'vital': VitalsComponent.VitalType.HEALTH, },
		{ 'bar': %FocusBar, 'vital': VitalsComponent.VitalType.FOCUS, },
	]
	for entry in config:
		entry.bar.max_value = vitals_component.get_vital_max(entry.vital)
		entry.bar.value = vitals_component.get_vital_current(entry.vital)
	vitals_component.vital_updated.connect(_on_vital_updated)

func run():
	running = true

func stop():
	running = false

func _on_vital_updated(update: VitalsComponent.VitalUpdate):
	for entry in config:
		if entry.vital != update.type:
			continue
		entry.bar.max_value = vitals_component.get_vital_max(entry.vital)
		entry.bar.value = vitals_component.get_vital_current(entry.vital)
