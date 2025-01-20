@tool
extends RefCounted

class_name TreePauser

var state: Dictionary[Node, Dictionary]

func pause_tree(node: Node, pause: bool):
	pause_node(node, pause)
	for c in node.get_children():
		pause_tree(c, pause)

func pause_node(node: Node, pause: bool):
	if pause == true:
		var node_state = {
			"process": node.is_processing(),
			"physics_process": node.is_physics_processing(),
			"process_input": node.is_processing_input(),
			"process_internal": node.is_processing_internal(),
			"process_unhandled_input": node.is_processing_unhandled_input(),
			"process_unhandled_key_input": node.is_processing_unhandled_key_input(),
		}
		state[node] = node_state
		node.set_process(false)
		node.set_physics_process(false)
		node.set_process_input(false)
		node.set_process_internal(false)
		node.set_process_unhandled_input(false)
		node.set_process_unhandled_key_input(false)
	else:
		var node_state = state.get(node, {})
		node.set_process(node_state.get("process", true))
		node.set_physics_process(node_state.get("physics_process", true))
		node.set_process_input(node_state.get("process_input", true))
		node.set_process_internal(node_state.get("process_internal", true))
		node.set_process_unhandled_input(node_state.get("process_unhandled_input", true))
		node.set_process_unhandled_key_input(node_state.get("process_unhandled_key_input", true))
