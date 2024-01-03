extends Window

var logging_component: LoggingComponent

func show_log(logging_component_: LoggingComponent):
	logging_component = logging_component_
	show()
	_update_logs_content()
	logging_component.log_entry_added.connect(_add_log_entry)

func _update_logs_content():
	%Logs.text = ""
	for log_entry in logging_component.entries:
		_add_log_entry(log_entry)

func _add_log_entry(log_entry: LoggingComponent.LogEntry):
	var entry_text = "[%0.2f] %s: %s\n" % [log_entry.time, LoggingComponent.short_log_type_name(log_entry.type), log_entry.message]
	%Logs.text += entry_text

func _on_close_requested():
	hide()
