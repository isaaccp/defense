extends EditorProperty

var options: OptionButton
# An internal value of the property.
var current_value: StringName
# A guard against internal changes when the property is updated.
var updating = false
var skills: Array[StringName]
var id_by_skill: Dictionary
# I don't understand why the property is updated twice when
# adding a new empty element. We want to show the pop-up only once.
var first = true

func _init():
	skills = SkillManager.all_skills
	options = OptionButton.new()
	options.add_item("")
	options.set_item_disabled(0, true)
	for i in range(skills.size()):
		var skill = skills[i]
		id_by_skill[skill] = i
		options.add_item(skill)
	add_child(options)
	add_focusable(options)
	refresh_options()
	options.item_selected.connect(_on_item_selected)

func _on_item_selected(index: int):
	# Ignore the signal if the property is currently being updated.
	if (updating):
		return
	# -1 to account for the empty placeholder.
	current_value = skills[index-1]
	emit_changed(get_edited_property(), current_value)

func _update_property():
	# Read the current value from the property.
	var new_value = get_edited_object()[get_edited_property()]
	# Futile attempt to popup.
	# The problem with this one is that in arrays this still triggers
	# for previously added entries, which I think get re-created every
	# time you add/remove. In practice if you just add new elements and
	# populate them it'd be fine, but kind of icky. Tried checking
	# if we are the last element of the array, but doesn't work as we
	# area always last when we are added.
	#if new_value == current_value:
		#if new_value == &"":
			#var parent = get_parent()
			#var grandparent = get_parent().get_parent()
			# Ugly check to see if this is an Array.
			#if grandparent is VBoxContainer:
				#if parent == grandparent.get_children()[-1]:
					#print("i am last")
					#get_tree().create_timer(0.05).timeout.connect(popup)
		#return

	# Update the control with the new value.
	updating = true
	current_value = new_value
	refresh_options()
	updating = false

func popup():
	if is_instance_valid(options):
		options.get_popup().grab_focus()
		options.show_popup()

func refresh_options():
	if current_value not in id_by_skill:
		options.select(0)
		return
	var id = id_by_skill[current_value]
	# To account for empty placeholder.
	options.select(id+1)
