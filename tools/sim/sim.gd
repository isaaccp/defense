extends SceneTree

# Thin SceneTree bootstrap for the sim tool. Cannot use project types at
# parse time because autoloads aren't registered yet — defers all real work
# to sim_runner.gd, which is loaded at runtime (autoloads available) and
# can use full static typing.
#
# See tools/sim/SIM.md for the full design and usage.
#
# Usage:
#   godot --headless --path . -s tools/sim/sim.gd -- <config.json>

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var runner_script := load("res://tools/sim/sim_runner.gd")
	var runner: Node = runner_script.new()
	runner.scene_tree = self
	runner.args = args
	root.add_child(runner)
