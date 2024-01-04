extends Window

var logging_component: LoggingComponent

# TODO: Optimize/GC/etc if the amount of logs becomes a problem.
func show_log(logging_component_: LoggingComponent):
	logging_component = logging_component_
	show()
	_update_logs_content()
	logging_component.log_entry_added.connect(_add_log_entry)

func reset():
	%Logs.text = ""
	if logging_component:
		logging_component.log_entry_added.disconnect(_add_log_entry)
	logging_component = null

func _update_logs_content():
	%Logs.text = ""
	for log_entry in logging_component.entries:
		_add_log_entry(log_entry)

func _log_type_color(log_type: LoggingComponent.LogType) -> String:
	match log_type:
		LoggingComponent.LogType.HEALTH:
			return "red"
		LoggingComponent.LogType.BEHAVIOR:
			return "lightblue"
		LoggingComponent.LogType.STATUS:
			return "lightgreen"
		LoggingComponent.LogType.HURT:
			return "firebrick"
		LoggingComponent.LogType.ACTION:
			return "lightgoldenrod"
	return "white"

func _add_log_entry(log_entry: LoggingComponent.LogEntry):
	var color = _log_type_color(log_entry.type)
	var entry_text = "[%0.2f] [color=%s]%s[/color]\n" % [log_entry.time, color, log_entry.message]
	%Logs.text += entry_text

func _on_close_requested():
	reset()
	hide()
