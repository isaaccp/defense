extends Resource

class_name StatusLibrary

@export var statuses: Array[StatusDef]:
	set(value):
		statuses = value
		_index()

var status_by_id: Dictionary

func _index():
	for status in statuses:
		status_by_id[status.id] = status
		
func get_status(status: StatusDef.Id) -> StatusDef:
	return status_by_id[status] as StatusDef
