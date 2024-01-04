@tool
extends Skill

class_name ConditionDef

enum Id {
	UNSPECIFIED,
	ALWAYS,
	TARGET_HEALTH,
}

# Type of condition.
enum Type {
	UNSPECIFIED,
	# Can be applied regardless of target.
	ANY,
	# Can be applied to targets of Target.Type.NODE as a filter.
	TARGET_NODE,
	# Condition applies to self (e.g. my health > X).
	SELF,
	# Some global condition that doesn't apply to targets, e.g.
	# number of characters/enemies left.
	GLOBAL,
}

@export var id: Id
@export var type: Type
@export var params: ConditionParams = ConditionParams.new()

# If true, it means it hasn't been parameterized through editor. Can't
# be used in a rule, etc.
@export_group("Internal")
@export var abstract = true
# Add more variables that can be set in editor.

static func condition_name(condition_id: Id) -> String:
	return Id.keys()[condition_id].capitalize()

# TODO: More constructors for different stuff, parameters, etc.
static func make(id: Id, type: Type) -> ConditionDef:
	var condition = ConditionDef.new()
	condition.id = id
	condition.type = type
	return condition

static func make_instance(id: Id, type: Type) -> ConditionDef:
	var condition = make(id, type)
	condition.abstract = false
	return condition

func name() -> String:
	return condition_name(id)

func _to_string() -> String:
	if not params or params.placeholders.size() == 0:
		return condition_name(id)
	else:
		return params.interpolated_text()

# TODO: Temporary for compatibility with Skill.
func get_id() -> int:
	return id
