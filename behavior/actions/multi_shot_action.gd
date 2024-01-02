extends BowAttackAction

var shots = 3

func post_initialize():
	for i in range(shots):
		spawn_arrow()
		await Global.get_tree().create_timer(0.33, false).timeout
	action_finished()
