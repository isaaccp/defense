extends Node

class_name LoggingComponent

const component = &"LoggingComponent"

signal log_entry_added(log_entry: LogEntry)

@export_group("Optional")
# Whether to track stats.
@export var track_stats = true

@export_group("Debug")
# When a log entry is added for those logtypes, it'll be immediately print()ed.
# TODO: Make a dictionary on _ready() if we have many.
@export var print_logtypes: Array[LogType]

# If set, log all messages to output.
# Can be set manually to debug when needed.
var log_all: bool = false

# Even if those look like they map to components, they are user-facing, so we
# shouldn't "ship our org chart" here and better to have a explicit LogType
# instead of e.g. using the component name.
enum LogType {
	UNSPECIFIED,
	BEHAVIOR,
	HEALTH,
	STATUS,
	HURT,
	ACTION,
}

class LogEntry extends RefCounted:
	var time: float
	var type: LogType
	var message: String
	var tooltip: String

	func _init(time_: float, type_: LogType, message_: String, tooltip_: String = ""):
		time = time_
		type = type_
		message = message_
		tooltip = tooltip_

	func _to_string():
		return "%0.2f: [%s] %s" % [time, LoggingComponent.log_type_name(type), message]

# TODO: Implement some max limit and rollover.
var entries: Array[LogEntry]
var stats = Stats.new()
var running = false
var elapsed_time = 0.0

func run():
	running = true

func _process(delta: float):
	if not running:
		return
	elapsed_time += delta

static func log_type_name(type: LogType):
	return LogType.keys()[type]

static func short_log_type_name(type: LogType):
	return LogType.keys()[type][0]

func add_log_entry(type: LogType, message: String, tooltip: String = "", stats_updates: Array[Stat] = [], time: float = -1.0):
	# this is there in case someone needs to provide log entries with time.
	if time < 0:
		time = elapsed_time
	var le = LogEntry.new(time, type, message, tooltip)
	entries.append(le)
	log_entry_added.emit(le)
	if log_all or type in print_logtypes:
		print("[%0.2f] %s(%s): %s" % [time, get_parent().actor_name, LoggingComponent.log_type_name(type), message])
	if track_stats:
		for stat in stats_updates:
			stats.add_stat(stat)
