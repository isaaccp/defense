extends RefCounted

class_name StateMachine

const debug = false

class State:
	var name: String
	var id: int
	## If set, this state is considered final and
	## only has enter method.
	var final: bool

	func _init(name: String, id: int, final: bool):
		self.name = name
		self.id = id
		self.final = final

	func enter_signal():
		return "%s_entered" % name

	func exit_signal():
		return "%s_existed" % name

	func enter_method():
		return "_on_%s_entered" % name

	func exit_method():
		return "_on_%s_exited" % name

var name: String
var id: int
var state: State
var states: Array[State]
var obj: Object

func _init(name: String):
	self.name = name
	self.id = Time.get_ticks_usec()
	state = null

func add(name: String, final = false):
	var state = State.new(name, id, final)
	states.push_back(state)
	return state

func current_state_name():
	return state.name

func is_state(state: State):
	assert(state.id == id)
	return self.state == state

func has_state(state_name: String):
	return states.any(func(s): return s.name == state_name)

func change_state(new_state: State, deferred = true):
	assert(new_state.id == id)
	if state != null:
		assert(not state.final)
		if state.name == new_state.name:
			return
		await obj.call(state.exit_method())
	if debug:
		print("State: %s: %s -> %s" % [name, state.name if state else "none", new_state.name])
	state = new_state
	if deferred:
		obj.call_deferred(state.enter_method())
	else:
		await obj.call(state.enter_method())

func connect_signals(obj: Object):
	self.obj = obj
	for s in states:
		assert(obj.has_method(s.enter_method()))
		if not s.final:
			assert(obj.has_method(s.exit_method()))
