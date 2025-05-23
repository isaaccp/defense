@tool
extends PopupPanel

var _item: TreeItem
var _col: int
var _params: SkillParams
var _acquired_skills: SkillTreeState

@onready var input = %Input

signal config_confirmed(item: TreeItem, col: int, result: String)

# NOTE: Just for testing the scene quickly, could be removed.
func _ready():
	%OK.disabled = true

func setup(item: TreeItem, col: int, acquired_skills: SkillTreeState) -> void:
	_item = item
	_col = col
	_params = item.get_metadata(col).params as SkillParams
	_acquired_skills = acquired_skills

	for c in input.get_children():
		input.remove_child(c)
	%OK.disabled = true
	_populate()
	show()

func _add_text(text: String):
	var l = Label.new()
	l.text = text
	input.add_child(l)

func _add_placeholder(placeholder_id: SkillParams.PlaceholderId):
	match placeholder_id:
		SkillParams.PlaceholderId.CMP:
			var opt = OptionButton.new()
			opt.add_item(SkillParams.placeholder_name(placeholder_id), 0)
			opt.set_item_disabled(0, true)
			opt.fit_to_longest_item = false
			for op in SkillParams.CmpOp.values():
				if op == SkillParams.CmpOp.UNSPECIFIED:
					continue
				opt.add_item(SkillParams.cmp_op_text(op), op)
			if _params.placeholder_set(SkillParams.PlaceholderId.CMP):
				opt.select(_params.get_placeholder_value(SkillParams.PlaceholderId.CMP))
			else:
				opt.select(0)
			opt.item_selected.connect(_on_cmp_op_selected.bind(placeholder_id))
			input.add_child(opt)
		SkillParams.PlaceholderId.INT_VALUE:
			var spin_box = SpinBox.new()
			spin_box.max_value = 999
			spin_box.set_update_on_text_changed(true)
			spin_box.set_select_all_on_focus(true)
			if _params.placeholder_set(SkillParams.PlaceholderId.INT_VALUE):
				spin_box.set_value(_params.get_placeholder_value(SkillParams.PlaceholderId.INT_VALUE))
			spin_box.value_changed.connect(_on_int_value_updated.bind(placeholder_id, spin_box))
			input.add_child(spin_box)
		SkillParams.PlaceholderId.FLOAT_VALUE:
			var spin_box = SpinBox.new()
			spin_box.max_value = 999
			spin_box.step = 0.1
			spin_box.set_update_on_text_changed(true)
			spin_box.set_select_all_on_focus(true)
			if _params.placeholder_set(SkillParams.PlaceholderId.FLOAT_VALUE):
				spin_box.set_value(_params.get_placeholder_value(SkillParams.PlaceholderId.FLOAT_VALUE))
			spin_box.value_changed.connect(_on_float_value_updated.bind(placeholder_id))
			input.add_child(spin_box)
		SkillParams.PlaceholderId.SORT:
			var opt = OptionButton.new()
			opt.add_item(SkillParams.placeholder_name(placeholder_id), 0)
			opt.set_item_disabled(0, true)
			opt.fit_to_longest_item = false

			var sort = _params.get_placeholder_value(SkillParams.PlaceholderId.SORT)
			var options = _acquired_skills.target_sorts
			for idx in range(options.size()):
				var sort_name = options[idx]
				opt.add_item(sort_name)
				if sort and sort.name == sort_name:
					opt.select(idx+1)
			opt.item_selected.connect(_on_sort_selected.bind(placeholder_id, options))
			input.add_child(opt)

func _populate():
	for part in _params.parts:
		if part is String:
			_add_text(part)
		elif part is SkillParams.PlaceholderId:
			_add_placeholder(part)

func _check_ok():
	if _params.all_set():
		%OK.disabled = false

func _on_cmp_op_selected(selection: int, placeholder: SkillParams.PlaceholderId):
	_params.set_placeholder_value(placeholder, selection)
	_check_ok()

func _on_int_value_updated(value: float, placeholder: SkillParams.PlaceholderId, spin_box: SpinBox):
	var int_value = int(value)
	# Make sure we keep the spinbox int.
	spin_box.set_value_no_signal(int_value)
	_params.set_placeholder_value(placeholder, int_value)
	_check_ok()

func _on_float_value_updated(value: float, placeholder: SkillParams.PlaceholderId):
	_params.set_placeholder_value(placeholder, value)
	_check_ok()

func _on_sort_selected(selection: int, placeholder: SkillParams.PlaceholderId, options: Array[StringName]):
	var name = options[selection-1]
	var sort = SkillManager.lookup_target_sort(name)
	assert(sort)
	_params.set_placeholder_value(placeholder, sort)
	_check_ok()

func results() -> SkillParams:
	return _params

func _on_ok_pressed():
	config_confirmed.emit(_item, _col, results())
	hide()

func _on_cancel_pressed():
	hide()
