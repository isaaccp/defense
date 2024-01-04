extends Resource

class_name StatusDef

# For now, make statuses just this id and see how it goes.
# We may want to make them something more substantial later.
enum Id {
	UNSPECIFIED,
	SWIFTNESS,
	STRENGTH_SURGE,
	PARALYZED,
}

@export var id: Id
@export var description: String
@export var icon: Texture2D

static func name(id: Id) -> String:
	return Id.keys()[id].capitalize()
