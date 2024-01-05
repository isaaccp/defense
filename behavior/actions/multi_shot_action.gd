extends BowAttackAction

var shots = 3

func _init():
	cooldown = 2.0

func post_initialize():
	for i in range(shots):
		spawn_arrow()
		await Global.get_tree().create_timer(0.33, false).timeout
		# Stop firing arrows if we are aborted.
		if finished:
			return
	action_finished()
