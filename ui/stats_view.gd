extends PanelContainer

class_name StatsView

func initialize(title: String, stat_names: Array[StringName], stats: Stats):
	%Title.text = title
	# Remove preview bits.
	for c in %Stats.get_children():
		c.queue_free()
	for sn in stat_names:
		var value = stats.get_value(sn)
		var text_val: String
		if typeof(value) == TYPE_FLOAT:
			text_val = str(snapped(value, 0.01))
		else:
			text_val = str(value)
		var name_label = Label.new()
		name_label.set_h_size_flags(Control.SIZE_EXPAND)
		name_label.text = sn.capitalize()
		var value_label = Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.custom_minimum_size = Vector2(60, 0)
		value_label.text = text_val
		%Stats.add_child(name_label)
		%Stats.add_child(value_label)
