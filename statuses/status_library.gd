extends Resource

class_name StatusLibrary

@export var statuses: Array[StatusDef]:
	set(value):
		statuses = value
		_index()

var status_by_name: Dictionary

func _index():
	for status in statuses:
		status_by_name[status.name] = status

func get_status(status: StringName) -> StatusDef:
	return status_by_name[status] as StatusDef
