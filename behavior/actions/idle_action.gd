extends Action

func _init():
	# Takes 1 second
	prepare_time = 0.0
	cooldown = 1.0

func post_initialize():
	Global.get_tree().create_timer(1.0, false).timeout.connect(action_finished)

func description():
	return "Idles for 1 second."
