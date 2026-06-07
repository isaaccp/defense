extends Action

class_name OpenAction

# Total channel time before the interactable opens. Movement out of range or
# target invalidation cancels the action.
@export var channel_time: float = 2.0

func _init():
	max_distance = 40.0
	min_distance = 0.0
	cooldown = 0.5
	focus_cost = 0.0
	abortable = true
	need_valid_target_after_prepare = true

func post_prepare():
	if not _after_await_check(true):
		return
	_channel()

func _channel():
	var elapsed := 0.0
	var tick := 0.1
	while elapsed < channel_time:
		await Global.get_tree().create_timer(tick, false).timeout
		if not _after_await_check(true):
			return
		if not in_range():
			action_finished()
			return
		elapsed += tick
	if not _after_await_check(true):
		return
	var interactable := target.actor as Interactable
	if interactable:
		interactable.open(actor)
	action_finished()

func description() -> String:
	return "Channels for %0.1f seconds to open the target interactable." % channel_time
