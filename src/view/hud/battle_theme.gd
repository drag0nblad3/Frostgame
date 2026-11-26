class_name BattleTheme
extends RefCounted
## Compact frosted-slate controls and high-contrast labels.


static func panel(color: Color, edge: Color, radius: int = 7) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 18
	var normal := panel(Color(0.075, 0.12, 0.18, 0.96), Color(0.27, 0.43, 0.56))
	var hover := panel(Color(0.15, 0.24, 0.32), Color(0.46, 0.70, 0.81))
	var selected := panel(Color(0.19, 0.42, 0.50), Color(0.62, 0.89, 0.96))
	var disabled := panel(Color(0.07, 0.10, 0.13, 0.8), Color(0.18, 0.23, 0.28))
	for kind: String in ["Button", "OptionButton", "MenuButton"]:
		theme.set_stylebox("normal", kind, normal)
		theme.set_stylebox("hover", kind, hover)
		theme.set_stylebox("pressed", kind, selected)
		theme.set_stylebox("disabled", kind, disabled)
		theme.set_color("font_color", kind, Color(0.92, 0.96, 1.0))
	theme.set_stylebox("panel", "PanelContainer", panel(Color(0.045, 0.075, 0.11, 0.88), Color(0.23, 0.37, 0.48)))
	return theme
