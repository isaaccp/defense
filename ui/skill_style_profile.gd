extends Resource
class_name SkillStyleProfile



@export var color_theme: Color
@export var corner_radius_top_left: int = 4
@export var corner_radius_top_right: int = 4
@export var corner_radius_bottom_right: int = 4
@export var corner_radius_bottom_left: int = 4

# Derived colors for stylebox backgrounds and borders
func bg_color_filled() -> Color:
	return Color(color_theme.r, color_theme.g, color_theme.b, 0.12)

func bg_color_highlight() -> Color:
	return Color(color_theme.r, color_theme.g, color_theme.b, 0.25)

func bg_color_empty() -> Color:
	return Color(color_theme.r, color_theme.g, color_theme.b, 0.01)

func border_color_filled() -> Color:
	return Color(color_theme.r, color_theme.g, color_theme.b, 0.5)

func border_color_highlight() -> Color:
	return Color(color_theme.r, color_theme.g, color_theme.b, 0.95)

func border_color_empty() -> Color:
	return Color(color_theme.r, color_theme.g, color_theme.b, 0.25)

func text_color_filled() -> Color:
	# Lighter tint of the theme color for clear contrast on dark/translucent panels
	return Color(
		lerp(color_theme.r, 1.0, 0.7),
		lerp(color_theme.g, 1.0, 0.7),
		lerp(color_theme.b, 1.0, 0.7)
	)

func text_color_empty() -> Color:
	return Color(color_theme.r, color_theme.g, color_theme.b, 0.4)
