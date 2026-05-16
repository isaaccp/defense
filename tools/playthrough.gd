extends SceneTree

# Thin SceneTree bootstrap. Cannot use project types at parse time because
# autoloads aren't registered yet — defers all real work to
# playthrough_runner.gd, which is loaded at runtime (autoloads available)
# and can use full static typing.
#
# See playthrough_runner.gd for usage and documentation.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var runner_script := load("res://tools/playthrough_runner.gd")
	var runner: Node = runner_script.new()
	runner.scene_tree = self
	runner.args = args
	root.add_child(runner)
