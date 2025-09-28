extends Action

const high_focus = preload("res://effects/statuses/high_focus.tres")

const high_focus_regen_multiplier: float = 5.0
const high_focus_duration: float = 5.0

func _init():
	prepare_time = 0.5
	cooldown = 15.0

func post_initialize():
	# Increases focus regeneration by 5x for 5 seconds.
	status_component.set_status(def.skill_name, high_focus, HighFocusParams.make(high_focus_regen_multiplier), high_focus_duration)
	Global.get_tree().create_timer(1.0, false).timeout.connect(action_finished)

func description():
	return "Meditates to re-focus, increasing focus regeneration by %fx for %fs." % [high_focus_regen_multiplier, high_focus_duration]
	
