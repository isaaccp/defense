extends Resource

class_name ConditionParams

enum CmpOp {
	UNSPECIFIED,
	LT,
	LE,
	EQ,
	GE,
	GT,
}

enum PlaceholderId {
	UNSPECIFIED,
	CMP,
	INT_VALUE,
}

# Probably build this later from some definition if it gets too complex.
# Examples:
#  "health {cmp} {int_value}"
@export var editor_string: String:
	set(value):
		editor_string = value
		_parse()

@export_group("Values")
@export var cmp: CmpOp
@export var int_value: IntValue

@export_group("Debug")
@export var valid: bool = true
@export var placeholders: Array[PlaceholderId]


func _parse():
	# TODO: Maybe check for mismatched { }.
	placeholders.clear()
	var re = RegEx.new()
	re.compile('{(?<placeholder>.+?)}')
	var result = re.search_all(editor_string)
	for r in result:
		var holder = r.get_string("placeholder")
		var added = _add_placeholder(holder)
		if not added:
			valid = false
			return
	valid = true

func _id_from_placeholder(holder: String) -> PlaceholderId:
	var upper = holder.to_upper()
	if not PlaceholderId.has(upper):
		return PlaceholderId.UNSPECIFIED
	return PlaceholderId.get(upper)

func _add_placeholder(holder: String) -> bool:
	var id = _id_from_placeholder(holder)
	if id == PlaceholderId.UNSPECIFIED:
		return false
	if id in placeholders:
		return false
	placeholders.append(id)
	return true
