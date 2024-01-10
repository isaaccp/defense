extends Actor

class_name ActionScene

@export_group("Optional")
## Set this to internal animation player in the scene
## if you want access in the action (e.g. to get the duration).
## TODO: Replace with AnimationComponent.
@export var animation_player: AnimationPlayer

var action_def: ActionDef
var owner_name: String

# From Body components.
var attributes_component: AttributesComponent
var side_component: SideComponent
var logging_component: LoggingComponent

# TODO: As of now animations on action scenes don't use the
# AnimationComponent and instead run automatically as soon as
# added. This is ~fine but wrong and they should be updated to
# use the AnimationComponent.
func _ready():
	# Only when launched with F6.
	if get_parent() == get_tree().root:
		_standalone_ready.call_deferred()
		# Action Scenes are instantiated during game an intended to be
		# run right away.
		return
	run.call_deferred()

func _standalone_ready():
	action_def = ActionDef.new()
	var parent = get_parent()
	parent.remove_child(self)
	var scene = load("res://behavior/actions/scenes/action_scene_player.tscn")
	var action_scene_player = scene.instantiate()
	action_scene_player.action_scene = load(scene_file_path)
	parent.add_child(action_scene_player)

func initialize(owner_name_: String, action_def_: ActionDef, target_: Target, attributes_component_: AttributesComponent, side_component_: SideComponent, logging_component_: LoggingComponent):
	owner_name = owner_name_
	action_def = action_def_
	attributes_component = attributes_component_
	side_component = side_component_
	logging_component = logging_component_

	var target_component = TargetComponent.get_or_null(self)
	if target_component:
		target_component.target = target_

func action_scene_log(message: String):
	if not logging_component:
		return
	var full_message = "%s: %s" % [name, message]
	logging_component.add_log_entry(LoggingComponent.LogType.ACTION, full_message)
