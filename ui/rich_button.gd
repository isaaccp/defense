extends Button

class_name RichButton

@export var label: RichTextLabel

var label_text: String:
	set(value):
		label.text = value

func disable():
	disabled = true
	modulate = Color(1, 1, 1, 0.5)
