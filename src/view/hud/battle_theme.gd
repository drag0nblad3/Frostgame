class_name BattleTheme
extends RefCounted
## Frosted slate, antique brass and parchment accents for fantasy tabletop UI.


static func panel(color: Color, edge: Color, radius: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = edge
	style.set_border_width_all(1)
	style.border_width_bottom = 2
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 18
	var normal := panel(Color(0.075, 0.11, 0.15, 0.97), Color(0.39, 0.43, 0.43))
	var hover := panel(Color(0.14, 0.22, 0.29), Color(0.72, 0.62, 0.39))
	var selected := panel(Color(0.19, 0.34, 0.40), Color(0.95, 0.78, 0.44))
	var disabled := panel(Color(0.07, 0.10, 0.13, 0.8), Color(0.18, 0.23, 0.28))
	var focus := panel(Color(0, 0, 0, 0), Color(0.96, 0.82, 0.50))
	focus.set_border_width_all(2)
	focus.draw_center = false
	for kind: String in ["Button", "OptionButton", "MenuButton"]:
		theme.set_stylebox("normal", kind, normal)
		theme.set_stylebox("hover", kind, hover)
		theme.set_stylebox("pressed", kind, selected)
		theme.set_stylebox("disabled", kind, disabled)
		theme.set_stylebox("focus", kind, focus)
		theme.set_color("font_color", kind, Color(0.94, 0.94, 0.88))
		theme.set_color("font_pressed_color", kind, Color(1.0, 0.91, 0.65))
		theme.set_color("font_hover_color", kind, Color(1.0, 0.95, 0.79))
	theme.set_stylebox("panel", "PanelContainer", panel(Color(0.045, 0.075, 0.11, 0.94), Color(0.53, 0.47, 0.33)))
	theme.set_stylebox("panel", "PopupMenu", panel(Color(0.055, 0.085, 0.12), Color(0.65, 0.54, 0.34)))
	theme.set_stylebox("hover", "PopupMenu", hover)
	theme.set_color("font_color", "PopupMenu", Color(0.94, 0.94, 0.88))
	theme.set_color("font_hover_color", "PopupMenu", Color(1.0, 0.90, 0.65))
	theme.set_constant("v_separation", "PopupMenu", 12)
	theme.set_constant("h_separation", "HBoxContainer", 6)
	theme.set_constant("v_separation", "VBoxContainer", 4)
	return theme
