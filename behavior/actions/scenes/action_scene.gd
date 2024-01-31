extends Actor

class_name ActionScene

@export_group("Required")
@export var target_position_type: Target.PositionType = Target.PositionType.DEFAULT
@export var hitbox_component: HitboxComponent

@export_group("Optional")
## Set this to internal animation player in the scene
## if you want access in the action (e.g. to get the duration).
## TODO: Replace with AnimationComponent.
@export var animation_player: AnimationPlayer

signal hit(hit_result: HitResult)

var action_def: ActionDef
var owner_name: String

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

func initialize(owner_name: String, action_def: ActionDef, target: Target, attributes: Attributes, side_component: SideComponent, logging_component: LoggingComponent):
	self.owner_name = owner_name
	self.action_def = action_def

	var target_component = TargetComponent.get_or_null(self)
	if target_component:
		target_component.action_target = ActionTarget.new(target, target_position_type)
	if hitbox_component:
		hitbox_component.initialize(owner_name, action_def, attributes, side_component, logging_component)
		hitbox_component.hit.connect(_on_hit)

func _on_hit(hit_result: HitResult):
	hit.emit(hit_result)
