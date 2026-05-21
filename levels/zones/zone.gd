@tool
extends Node2D

class_name Zone

# An explicitly-declared region of a stage. Zones partition the playfield so
# decoration coverage is auditable: every part of the stage belongs to a named
# Zone, and every OPEN/ENCLOSED zone is expected to carry decoration
# (DecorationScatter children) unless `deliberately_bare` is set.
#
# DecorationScatter children inherit this zone's `kind`, and its `area` too
# unless the scatter sets its own (a sub-region of the zone).

enum Kind {
	OPEN,      ## Walkable gameplay space. Random scatter filters colliding props.
	ENCLOSED,  ## Walled off from gameplay. Scatter may place colliding props.
	SOLID,     ## A building / solid-object footprint. No decoration at all.
}

@export var kind: Kind = Kind.OPEN: set = _set_kind
@export var area: ScatterArea: set = _set_area
## An OPEN/ENCLOSED zone that intentionally carries no decoration (e.g. a
## path-filled corridor). Suppresses the "undecorated zone" audit warning.
@export var deliberately_bare: bool = false

func _ready() -> void:
	# y-sort so child scatters' decorations merge into the stage's y-sort.
	y_sort_enabled = true

func _set_kind(v: Kind) -> void:
	kind = v
	queue_redraw()

func _set_area(v: ScatterArea) -> void:
	area = v
	update_configuration_warnings()
	queue_redraw()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not area:
		warnings.append("area is not set — assign a ScatterArea.")
	return warnings

func _draw() -> void:
	if Engine.is_editor_hint() and area:
		area.draw_boundary(self)
