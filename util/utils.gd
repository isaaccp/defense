@tool
extends Object

class_name Utils

static func filter_and_join_strings(strings: Array) -> String:
	var filtered_strings = strings.filter(func(s): return not s.is_empty())
	return ", ".join(filtered_strings)
