extends SceneTree

# Thin SceneTree bootstrap for the campaign sim tool. Cannot use project types at
# parse time because autoloads aren't registered yet — defers all real work
# to campaign_sim_runner.gd, which is loaded at runtime.
#
# Usage:
#   godot --headless --path . -s tools/sim/campaign_sim.gd -- <args>

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var runner_script := load("res://tools/sim/campaign_sim_runner.gd")
	var runner: Node = runner_script.new()
	runner.scene_tree = self
	runner.args = args
	root.add_child(runner)
