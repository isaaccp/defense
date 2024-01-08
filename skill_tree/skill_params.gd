@tool
extends Resource

class_name SkillParams

enum PlaceholderId {
	UNSPECIFIED,
	CMP,
	INT_VALUE,
	FLOAT_VALUE,
	SORT,
}

enum CmpOp {
	UNSPECIFIED,
	LT,
	LE,
	EQ,
	GE,
	GT,
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
@export var float_value: FloatValue
@export var sort: TargetSort

# Don't want those to end up saved in resources.
# @export_group("Debug")
var valid: bool = true
var placeholders: Array[PlaceholderId]
var parts: Array[Variant]

func _init():
	# Needs to be called deferred so values from resource are set.
	_parse.call_deferred()

func set_placeholder_value(placeholder: PlaceholderId, value: Variant):
	match placeholder:
		PlaceholderId.CMP:
			assert(typeof(value) == TYPE_INT)
			cmp = value as CmpOp
		PlaceholderId.INT_VALUE:
			assert(typeof(value) == TYPE_INT)
			int_value = IntValue.make(value)
		PlaceholderId.FLOAT_VALUE:
			assert(typeof(value) == TYPE_FLOAT)
			float_value = FloatValue.make(value)
		PlaceholderId.SORT:
			assert(value is TargetSort)
			sort = value as TargetSort

func get_placeholder_string(placeholder: PlaceholderId) -> String:
	match placeholder:
		PlaceholderId.CMP:
			return SkillParams.cmp_op_text(cmp)
		PlaceholderId.INT_VALUE:
			return str(int_value.value)
		PlaceholderId.FLOAT_VALUE:
			return "%0.1f" % float_value.value
		PlaceholderId.SORT:
			return str(sort)

	assert(false, "Unreachable")
	return "<bug>"

# Precondition: placeholder_set() has returned true for this placeholder.
func get_placeholder_value(placeholder: PlaceholderId) -> Variant:
	match placeholder:
		PlaceholderId.CMP:
			return cmp
		PlaceholderId.INT_VALUE:
			return int_value.value
		PlaceholderId.FLOAT_VALUE:
			return float_value.value
		PlaceholderId.SORT:
			return sort
	assert(false, "Unreachable")
	return null

func all_set() -> bool:
	if not valid:
		return false
	var ret = true
	for placeholder in placeholders:
		ret = placeholder_set(placeholder)
		if not ret:
			break
	return ret

func interpolated_text() -> String:
	var text = ""
	for part in parts:
		if part is String:
			text += part
		elif part is PlaceholderId:
			if placeholder_set(part):
				var value = get_placeholder_string(part)
				text += str(value)
			else:
				text += _placeholder_text(part)
	return text

func _placeholder_text(placeholder: PlaceholderId) -> String:
	return "{%s}" % PlaceholderId.keys()[placeholder].to_lower()

func placeholder_set(placeholder: PlaceholderId) -> bool:
	match placeholder:
		PlaceholderId.CMP:
			return cmp != CmpOp.UNSPECIFIED
		PlaceholderId.INT_VALUE:
			return int_value and int_value.defined
		PlaceholderId.FLOAT_VALUE:
			return float_value and float_value.defined
		PlaceholderId.SORT:
			return sort != null
	assert(false, "unreachable")
	return false

func _parse():
	# TODO: Maybe check for mismatched { }.
	placeholders.clear()
	parts.clear()
	var re = RegEx.new()
	re.compile('(?<prefix>.*?){(?<placeholder>.+?)}')
	var result = re.search_all(editor_string)
	var end = 0
	for r in result:
		var prefix = r.get_string("prefix")
		if not prefix.is_empty():
			_add_part(prefix)
		var holder = r.get_string("placeholder")
		var added = _add_placeholder(holder)
		if not added:
			valid = false
			return
		end = r.get_end()
	var eol = editor_string.substr(end)
	if not eol.is_empty():
		_add_part(eol)
	valid = true

func _id_from_placeholder(holder: String) -> PlaceholderId:
	var upper = holder.to_upper()
	if not PlaceholderId.has(upper):
		return PlaceholderId.UNSPECIFIED
	return PlaceholderId.get(upper)

func _add_part(v: Variant):
	parts.append(v)

func _add_placeholder(holder: String) -> bool:
	var id = _id_from_placeholder(holder)
	if id == PlaceholderId.UNSPECIFIED:
		return false
	if id in placeholders:
		return false
	placeholders.append(id)
	_add_part(id)
	return true

static func placeholder_name(id: PlaceholderId) -> String:
	return PlaceholderId.keys()[id]

static func cmp_op_text(op: CmpOp) -> String:
	match op:
		SkillParams.CmpOp.LT:
			return "<"
		SkillParams.CmpOp.LE:
			return "<="
		SkillParams.CmpOp.EQ:
			return "="
		SkillParams.CmpOp.GE:
			return ">="
		SkillParams.CmpOp.GT:
			return ">"
	assert(false, "unreachable")
	return "<bug>"
