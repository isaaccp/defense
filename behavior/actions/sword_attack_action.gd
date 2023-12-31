extends Action

const sword_attack_scene = preload("res://behavior/actions/scenes/sword_attack.tscn")

var sword_attack: Node2D
var damage = 5

func _init():
	distance = 40

func physics_process(target: Node2D, delta: float):
	if not sword_attack:
		var dir = (target.position - body.position).normalized()
		sword_attack = sword_attack_scene.instantiate()
		sword_attack.look_at(sword_attack.position + dir)
		sword_attack.position += dir * 35
		# TODO: Likely make a method for this, but unclear what it may
		# need to do.
		action_sprites.add_child(sword_attack)
		sword_attack.hurtbox_hit.connect(_on_hurtbox_hit)
		Global.get_tree().create_timer(1.0, false).timeout.connect(action_finished)

# TODO: Probably could be moved to base class.
func _on_hurtbox_hit(hurtbox: HurtboxComponent):
	if friendly_fire:  # No checks needed.
		if hurtbox.can_handle_collision():
			hurtbox.handle_collision(damage)
	else:
		if side_component.is_enemy(hurtbox.side_component):
			if hurtbox.can_handle_collision():
				hurtbox.handle_collision(damage)

func action_finished():
	sword_attack.queue_free()
	super()
