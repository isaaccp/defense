@tool
extends Object

class_name Utils

static func filter_and_join_strings(strings: Array, separator = ", ") -> String:
	var filtered_strings = strings.filter(func(s): return not s.is_empty())
	return separator.join(filtered_strings)
