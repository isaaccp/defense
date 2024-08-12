extends Window

var logging_component: LoggingComponent

# TODO: Optimize/GC/etc if the amount of logs becomes a problem.
func show_log(actor_name: String, logging_component_: LoggingComponent):
	reset()
	title = "Log Viewer: %s" % actor_name
	logging_component = logging_component_
	show()
	_update_logs_content()
	logging_component.log_entry_added.connect(_add_log_entry)

func reset():
	%Logs.text = ""
	if is_instance_valid(logging_component):
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
	%Logs.append_text("[%0.2f] " % log_entry.time)
	if not log_entry.tooltip.is_empty():
		%Logs.push_hint(log_entry.tooltip)
	var color = _log_type_color(log_entry.type)
	%Logs.append_text("[color=%s]%s[/color]\n" % [color, log_entry.message])
	if not log_entry.tooltip.is_empty():
		%Logs.pop()

func _on_close_requested():
	reset()
	hide()
