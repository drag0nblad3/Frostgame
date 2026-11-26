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
	# Larger embedded window X and scroll tracks, in logical UI units.
	# A 42-unit close icon has a much larger hit target than Godot's default.
	var close := _close_texture(Color("e9e3d3"),Color("344752"))
	var close_pressed := _close_texture(Color.WHITE,Color("8a5b3d"))
	theme.set_icon("close","Window",close)
	theme.set_icon("close_pressed","Window",close_pressed)
	theme.set_constant("title_height","Window",58)
	theme.set_constant("close_h_offset","Window",48)
	theme.set_constant("close_v_offset","Window",50)
	theme.set_font_size("title_font_size","Window",22)
	var track := panel(Color("24333d"),Color("52626a"),4)
	track.set_content_margin_all(14)
	var grab := panel(Color("9eacb0"),Color("d1dbd9"),5)
	grab.set_content_margin_all(14)
	var active := panel(Color("d6bd82"),Color("f5dfad"),5)
	active.set_content_margin_all(14)
	for kind: String in ["VScrollBar","HScrollBar"]:
		theme.set_stylebox("scroll",kind,track)
		theme.set_stylebox("scroll_focus",kind,track)
		theme.set_stylebox("grabber",kind,grab)
		theme.set_stylebox("grabber_highlight",kind,active)
		theme.set_stylebox("grabber_pressed",kind,active)
	theme.set_constant("v_separation", "PopupMenu", 16)
	theme.set_constant("scrollbar_h_separation","ScrollContainer",10)
	theme.set_constant("scrollbar_v_separation","ScrollContainer",10)
	theme.set_constant("h_separation","TabContainer",12)
	theme.set_constant("h_separation", "HBoxContainer", 6)
	theme.set_constant("v_separation", "VBoxContainer", 4)
	return theme


static var _close_icons := {}


static func _close_texture(foreground: Color,background: Color) -> Texture2D:
	var key := str(foreground)+str(background)
	if _close_icons.has(key):
		return _close_icons[key]
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="42" height="42" viewBox="0 0 42 42"><rect x="1" y="1" width="40" height="40" rx="7" fill="#%s"/><path d="M13 13 L29 29 M29 13 L13 29" stroke="#%s" stroke-width="3.8" stroke-linecap="round"/></svg>'%[background.to_html(false),foreground.to_html(false)]
	var image := Image.new()
	image.load_svg_from_string(svg)
	var texture := ImageTexture.create_from_image(image)
	_close_icons[key]=texture
	return texture
