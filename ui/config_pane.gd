extends PopupPanel

var _item: TreeItem
var _col: int
var _set: Array[bool]

@onready var input = %Input

signal config_confirmed(item: TreeItem, col: int, result: String)

# NOTE: Just for testing the scene quickly, could be removed.
func _ready():
	%OK.disabled = true
	_parse_opts("{bar} baz {qux} etc")

func setup(item: TreeItem, col: int) -> void:
	_item = item
	_col = col

	for c in input.get_children():
		input.remove_child(c)
	%OK.disabled = true
	_parse_opts(item.get_text(col))
	show()

func _parse_opts(txt: String):
	# FIXME: Use real metadata structure to figure this out.
	var re = RegEx.new()
	re.compile('(?<prefix>.*?){(?<placeholder>.+?)}')
	var result = re.search_all(txt)
	var end = 0
	var idx = 0
	_set.resize(0)
	for r in result:
		var pre = r.get_string("prefix")
		var l = Label.new()
		l.text = pre
		input.add_child(l)

		var holder = r.get_string("placeholder")
		var opt = OptionButton.new()
		opt.add_item(holder, 0)
		opt.set_item_disabled(0, true)
		opt.fit_to_longest_item = false

		# FIXME: From metadata
		opt.add_item("Some long option name")
		opt.add_item("HP")
		opt.select(0)
		opt.item_selected.connect(_on_opt_selected.bind(idx))
		input.add_child(opt)
		_set.append(false)

		end = r.get_end()
		idx += 1

	var eol = txt.substr(end)
	var t = Label.new()
	t.text = eol
	input.add_child(t)

func _on_opt_selected(_selection: int, placeholder: int):
	# Make sure everything has been filled in before enabling the OK button
	_set[placeholder] = true
	for v in _set:
		if not v:
			return
	%OK.disabled = false

func results() -> String:
	# FIXME: Structured result (the full behavior or something?)
	var out := ""
	for c in input.get_children():
		if c is Label:
			out += c.text
		if c is OptionButton:
			# Keep the placeholder so you can edit again...
			out += "{%s}" % c.text
	return out

func _on_ok_pressed():
	config_confirmed.emit(_item, _col, results())
	hide()

func _on_cancel_pressed():
	hide()
