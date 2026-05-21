extends SceneTree

# Prints the world positions of a scatter node's spawned children, sorted by Y.
# Usage: godot --path . -s tools/dump_scatter.gd -- <stage_scene> <node_path>

var _scene: Node
var _node_path: String
var _frames := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path: String = args[0]
	_node_path = args[1]
	if not scene_path.begins_with("res://"):
		scene_path = "res://" + scene_path
	var packed := load(scene_path) as PackedScene
	var vp := SubViewport.new()
	vp.size = Vector2i(960, 540)
	root.add_child(vp)
	_scene = packed.instantiate()
	vp.add_child(_scene)

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 6:
		return false
	var node := _scene.get_node(_node_path)
	var rows: Array = []
	var trees := 0
	var companions := 0
	for c in node.get_children():
		var is_tree: bool = c is PhysicsBody2D
		if is_tree:
			trees += 1
		else:
			companions += 1
		rows.append({ "pos": c.position, "name": str(c.name), "tree": is_tree })
	rows.sort_custom(func(a, b): return a["pos"].y < b["pos"].y)
	print("=== %s : %d children (%d trees, %d companions), sorted by Y ===" % [
		_node_path, rows.size(), trees, companions])
	for r in rows:
		var p: Vector2 = r["pos"]
		print("  %-7s (%7.2f, %7.2f)  %s" % ["TREE" if r["tree"] else "comp", p.x, p.y, r["name"]])
	return true
