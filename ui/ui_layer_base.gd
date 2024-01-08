extends CanvasLayer

class_name UILayerBase

@export_group("Internal")
@export var screens: Control
@export var initial_screen: Control

var current_screen: Control

# Called when the node enters the scene tree for the first time.
func _ready():
	for screen in screens.get_children():
		screen._setup_screen(self)
	if is_instance_valid(initial_screen):
		show_screen(initial_screen)

func show_screen(screen: Control, info: Dictionary = {}) -> void:
	hide_screen()
	screen.show()
	screen._on_show(info)
	current_screen = screen

func hide_screen() -> void:
	if is_instance_valid(current_screen):
		current_screen._on_hide()
		current_screen.hide()
