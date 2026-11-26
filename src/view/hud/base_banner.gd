class_name BaseBanner
extends VBoxContainer
## Compact architectural illustration for the actual base, with read-only benefits.
const ART := {
	"camp": preload("res://assets/base-art/camp.svg"),
	"inn": preload("res://assets/base-art/inn.svg"),
	"brewery": preload("res://assets/base-art/brewery.svg"),
	"laboratory": preload("res://assets/base-art/laboratory.svg"),
	"treasury": preload("res://assets/base-art/treasury.svg"),
	"temple": preload("res://assets/base-art/temple.svg"),
	"crypt": preload("res://assets/base-art/crypt.svg"),
	"tower": preload("res://assets/base-art/tower.svg"),
	"library": preload("res://assets/base-art/library.svg")
}
var _art: TextureRect
var _caption: Label


func _ready() -> void:
	_art = TextureRect.new()
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.custom_minimum_size.y = 150
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	_caption = Label.new()
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.modulate = Color(0.95,0.87,0.68)
	add_child(_caption)
	refresh({})


func refresh(data: Dictionary) -> void:
	var id := str(data.get("base",""))
	_art.texture = ART.get(id,ART["camp"])
	var name := id.capitalize() if not id.is_empty() else "Expedition camp"
	var benefit := str(BaseRules.BENEFITS.get(id,"No permanent headquarters selected."))
	_caption.text = "%s  •  %s  •  %d resources" % [name,benefit,data.get("resources",[]).size()]
