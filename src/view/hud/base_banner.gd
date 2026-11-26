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
var _resources: HFlowContainer


func _ready() -> void:
	_art = TextureRect.new()
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.custom_minimum_size.y = 150
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	_caption = Label.new()
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.modulate = Color(0.95,0.87,0.68)
	add_child(_caption)
	_resources = HFlowContainer.new()
	add_child(_resources)
	refresh({})


func refresh(data: Dictionary) -> void:
	var id := str(data.get("base",""))
	_art.texture = ART.get(id,ART["camp"])
	var name := id.capitalize() if not id.is_empty() else "Expedition camp"
	var benefit := str(BaseRules.BENEFITS.get(id,"No permanent headquarters selected."))
	_caption.text = "%s  •  %s  •  %d resources" % [name,benefit,data.get("resources",[]).size()]
	for child in _resources.get_children():
		_resources.remove_child(child)
		child.queue_free()
	var catalog := BaseResources.catalog()
	for resource: String in data.get("resources",[]):
		var info: Dictionary = catalog.get(resource,{})
		var tag := PanelContainer.new()
		tag.add_theme_stylebox_override("panel",BattleTheme.panel(Color(0.10,0.17,0.21),Color(0.50,0.45,0.31),3))
		var row := HBoxContainer.new()
		tag.add_child(row)
		var icon := TextureRect.new()
		icon.texture = ResourceArt.icon(resource)
		icon.custom_minimum_size = Vector2(30,30)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var label := Label.new()
		label.text = str(info.get("name",resource.capitalize()))
		label.add_theme_font_size_override("font_size",14)
		row.add_child(label)
		tag.tooltip_text = str(info.get("benefit",""))
		_resources.add_child(tag)
