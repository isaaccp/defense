extends Action

const sword_attack_scene = preload("res://behavior/actions/scenes/sword_attack.tscn")

var sword_attack: Node2D

func _init():
	distance = 50

func physics_process(target: Node2D, delta: float):
	if not sword_attack:
		var dir = (target.position - entity.position).normalized()
		sword_attack = sword_attack_scene.instantiate()
		sword_attack.look_at(target.position)
		sword_attack.position += dir * 30
		# TODO: Likely make a method for this, but unclear what it may
		# need to do.
		entity.action_sprites.add_child(sword_attack)
		sword_attack.entity_hit.connect(_on_entity_hit)
		# TODO: Connect some signals here to notify of end of action. For now
		# hack a timer.
		var timer = Global.get_tree().create_timer(2.0, false)
		timer.timeout.connect(action_finished)

func _on_entity_hit(hit_entity: BehaviorEntity):
	if friendly_fire:  # No checks needed.
		_process_hit(hit_entity)
	else:
		if entity.is_enemy(hit_entity):
			_process_hit(hit_entity)
	
func _process_hit(hit_entity: BehaviorEntity):
	print("%s was hit!" % hit_entity.name)

func action_finished():
	sword_attack.queue_free()
	super()
