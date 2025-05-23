extends Node

class_name AutoFreeComponent

const component = &"AutoFreeComponent"

@export_group("Optional")
## If > 0, free after this time.
@export var free_after_secs: float = -1.0
## If animation_component is provided, will free after animation finishes.
@export var animation_component: AnimationComponent
# Remove animation_player once everyone has moved to animation_component.
## If hitbox_component is provided, will free after all hits used.
@export var hitbox_component: HitboxComponent
# TODO: Implement "free if it goes out of screen"
## For cases in which we want to free when moving is over (e.g. arrows).
@export var motion_component: MotionComponentBase

signal freed

func run():
	if animation_component:
		animation_component.animation_finished.connect(
			func(_anim): AutoFreeComponent._free_parent(self))
	if hitbox_component:
		hitbox_component.all_hits_used.connect(
			AutoFreeComponent._free_parent.bind(self))
	if motion_component:
		motion_component.motion_done.connect(
			AutoFreeComponent._free_parent.bind(self))
	if free_after_secs > 0:
		var timer = %Timer as Timer
		timer.start(free_after_secs)
		timer.timeout.connect(
			AutoFreeComponent._free_parent.bind(self))

static func _free_parent(node: Node) -> void:
	if is_instance_valid(node):
		var parent = node.get_parent()
		if is_instance_valid(parent):
			node.freed.emit()
			parent.queue_free()
