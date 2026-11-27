class_name MenuSymbols
extends RefCounted
## Imported textures, not font-dependent glyphs or runtime SVG decoding.
const ICONS := {
	"back": preload("res://assets/glyphs/nav_back.svg"),
	"close": preload("res://assets/glyphs/nav_close.svg"),
	"save": preload("res://assets/glyphs/nav_save.svg"),
	"menu": preload("res://assets/glyphs/nav_menu.svg")
}


static func apply(button: Button,kind: String,description: String,icon_only: bool=false) -> void:
	button.icon=ICONS[kind]
	button.expand_icon=true
	button.add_theme_constant_override("icon_max_width",36)
	button.add_theme_constant_override("h_separation",8)
	button.custom_minimum_size=button.custom_minimum_size.max(Vector2(64,64))
	button.tooltip_text=description
	if icon_only:
		button.text=""
		button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
