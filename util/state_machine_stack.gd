extends RefCounted

class_name StateMachineStack

# A chain of states. Useful to keep track of states across a hierarchy of objects
# that use StateMachine, e.g. to have a full state view without big dependencies.

var state_machines: Array
var sm_by_name: Dictionary

func _init(root_sm: StateMachine):
	state_machines.append(root_sm)
	sm_by_name[root_sm.name] = root_sm

func add_state_machine(sm: StateMachine):
	state_machines.append(sm)
	sm_by_name[sm.name] = sm

func remove_state_machine(sm: StateMachine):
	assert(state_machines[-1] == sm)
	assert(sm.name in sm_by_name)
	sm_by_name.erase(sm.name)
	state_machines.pop_back()

func has_state_machine(name: String) -> bool:
	return name in sm_by_name

func get_state_machine(name: String) -> StateMachine:
	return sm_by_name.get(name)
