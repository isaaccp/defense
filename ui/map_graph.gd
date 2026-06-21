extends Control
class_name MapGraph

signal node_clicked(node: RewardNode)
signal node_hovered(node: RewardNode)
signal node_unhovered(node: RewardNode)

const reward_node_scene = preload("res://ui/reward_node.tscn")

var _stage_rewards: StageRewards
var _paths: Array[Array] = [] # Array of Arrays of RewardNodes
var _next_stage_node: RewardNode

var _chosen_path_idx: int = -1
var _bg_hovered_path_idx: int = -1
var _node_hovered_path_idx: int = -1

@onready var path0_hover = $Path0_HoverArea
@onready var path1_hover = $Path1_HoverArea

var map_visual

const MapVisualClass = preload("res://ui/map_visual.gd")

func _ready() -> void:
	if path0_hover:
		path0_hover.mouse_entered.connect(func(): _on_path_hover(0))
		path0_hover.mouse_exited.connect(func(): _on_path_unhover(0))
		path0_hover.gui_input.connect(func(event): _on_path_input(0, event))
	if path1_hover:
		path1_hover.mouse_entered.connect(func(): _on_path_hover(1))
		path1_hover.mouse_exited.connect(func(): _on_path_unhover(1))
		path1_hover.gui_input.connect(func(event): _on_path_input(1, event))
		
	for child in get_children():
		if child is MapVisualClass:
			map_visual = child
			break

func _on_path_input(path_idx: int, event: InputEvent) -> void:
	if _chosen_path_idx != -1: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		lock_path(path_idx)

func setup(rewards: StageRewards) -> void:
	_stage_rewards = rewards
	_chosen_path_idx = -1
	_bg_hovered_path_idx = -1
	_node_hovered_path_idx = -1
	
	if not map_visual:
		return
		
	# Clear existing slots
	for slot in map_visual.path_0_slots + map_visual.path_1_slots + [map_visual.next_stage_slot]:
		if slot:
			for child in slot.get_children():
				child.queue_free()
		
	_paths.clear()
	_build_nodes()

func _build_nodes() -> void:
	if not map_visual: return
	
	var path_count = _stage_rewards.sets.size()
	
	for path_idx in path_count:
		var path_nodes: Array[RewardNode] = []
		var reward_set = _stage_rewards.sets[path_idx]
		
		var visual_slots = map_visual.path_0_slots if path_idx == 0 else map_visual.path_1_slots
		
		# Slot assignment
		var slot_indices = []
		if reward_set.rewards.size() == 1:
			slot_indices = [1]
		elif reward_set.rewards.size() == 2:
			slot_indices = [0, 2]
		elif reward_set.rewards.size() >= 3:
			slot_indices = [0, 1, 2]
			
		for i in range(min(reward_set.rewards.size(), visual_slots.size())):
			var reward = reward_set.rewards[i]
			var node = reward_node_scene.instantiate() as RewardNode
			
			var slot_idx = slot_indices[i]
			var slot = visual_slots[slot_idx]
			if slot:
				slot.add_child(node)
			
			node.position = -node.size / 2.0
			node.setup(reward)
			node.clicked.connect(func(n): _on_node_clicked(path_idx, n))
			node.hovered.connect(func(n):
				if _chosen_path_idx == -1:
					_node_hovered_path_idx = path_idx
					_update_visuals()
				node_hovered.emit(n)
			)
			node.unhovered.connect(func(n):
				if _chosen_path_idx == -1 and _node_hovered_path_idx == path_idx:
					_node_hovered_path_idx = -1
					_update_visuals()
				node_unhovered.emit(n)
			)
			
			path_nodes.append(node)
			
		_paths.append(path_nodes)
		
	if map_visual.next_stage_slot:
		_next_stage_node = reward_node_scene.instantiate() as RewardNode
		map_visual.next_stage_slot.add_child(_next_stage_node)
		_next_stage_node.position = -_next_stage_node.size / 2.0
		_next_stage_node.setup(null, true)
		_next_stage_node.clicked.connect(func(_n): _on_next_stage_clicked())
		_next_stage_node.hovered.connect(func(n): node_hovered.emit(n))
		_next_stage_node.unhovered.connect(func(n): node_unhovered.emit(n))
	
	_update_node_states()

func _on_path_hover(path_idx: int) -> void:
	if _chosen_path_idx != -1: return
	_bg_hovered_path_idx = path_idx
	_update_visuals()

func _on_path_unhover(path_idx: int) -> void:
	if _chosen_path_idx != -1: return
	if _bg_hovered_path_idx == path_idx:
		_bg_hovered_path_idx = -1
		_update_visuals()

func _on_node_clicked(path_idx: int, node: RewardNode) -> void:
	if _chosen_path_idx == -1:
		_chosen_path_idx = path_idx
		_update_node_states()
	
	if path_idx == _chosen_path_idx:
		node_clicked.emit(node)

func _on_next_stage_clicked() -> void:
	if _chosen_path_idx != -1:
		node_clicked.emit(_next_stage_node)

func lock_path(path_idx: int) -> void:
	_chosen_path_idx = path_idx
	_update_node_states()

func update_all_nodes() -> void:
	_update_node_states()

func get_chosen_path_idx() -> int:
	return _chosen_path_idx

func get_nodes_in_path(path_idx: int) -> Array[RewardNode]:
	if path_idx >= 0 and path_idx < _paths.size():
		return _paths[path_idx].duplicate()
	return []

func _update_node_states() -> void:
	if _chosen_path_idx == -1:
		for path in _paths:
			for node in path:
				node.set_state(RewardNode.State.PRECHOICE)
		if _next_stage_node:
			_next_stage_node.set_state(RewardNode.State.GREYED)
	else:
		for p_idx in _paths.size():
			var path = _paths[p_idx]
			if p_idx == _chosen_path_idx:
				for node in path:
					if node.state == RewardNode.State.PRECHOICE:
						node.set_state(RewardNode.State.PENDING)
			else:
				for node in path:
					node.set_state(RewardNode.State.GREYED)
		
		if _next_stage_node:
			_next_stage_node.set_state(RewardNode.State.PENDING)
			
	_update_visuals()

func _update_visuals() -> void:
	# Reset highlights and tooltips
	for p_idx in _paths.size():
		for node in _paths[p_idx]:
			node.set_highlighted(false)
			node.set_floating_tooltip_visible(false)
	
	if _next_stage_node:
		_next_stage_node.set_highlighted(false)
		_next_stage_node.set_floating_tooltip_visible(false)
			
	if not map_visual: return
	
	map_visual.reset_path_highlights()
	
	if _chosen_path_idx == -1:
		var effective_hover = _node_hovered_path_idx
		if effective_hover == -1:
			effective_hover = _bg_hovered_path_idx
			
		if effective_hover == 0:
			map_visual.set_path_dimmed(0, false)
			map_visual.set_path_highlighted(0, true)
			map_visual.set_path_dimmed(1, true)
			if _paths.size() > 0:
				for node in _paths[0]: 
					node.set_highlighted(true)
					node.set_floating_tooltip_visible(true)
		elif effective_hover == 1:
			map_visual.set_path_dimmed(0, true)
			map_visual.set_path_dimmed(1, false)
			map_visual.set_path_highlighted(1, true)
			if _paths.size() > 1:
				for node in _paths[1]: 
					node.set_highlighted(true)
					node.set_floating_tooltip_visible(true)
		else:
			map_visual.reset_dimming()
	else:
		if _chosen_path_idx == 0:
			map_visual.set_path_dimmed(0, false)
			map_visual.set_path_dimmed(1, true)
		elif _chosen_path_idx == 1:
			map_visual.set_path_dimmed(0, true)
			map_visual.set_path_dimmed(1, false)
			
		# Highlight remaining pending nodes on the chosen path
		if _chosen_path_idx >= 0 and _chosen_path_idx < _paths.size():
			for node in _paths[_chosen_path_idx]:
				if node.state == RewardNode.State.PENDING:
					node.set_highlighted(true)
			
		# Highlight next stage if all rewards claimed
		if _next_stage_node and _next_stage_node.state == RewardNode.State.PENDING:
			var all_claimed = true
			if _chosen_path_idx >= 0 and _chosen_path_idx < _paths.size():
				for n in _paths[_chosen_path_idx]:
					if n.state != RewardNode.State.DONE:
						all_claimed = false
						break
			if all_claimed:
				_next_stage_node.set_highlighted(true)
