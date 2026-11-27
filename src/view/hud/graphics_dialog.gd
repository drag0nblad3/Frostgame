class_name GraphicsDialog
extends ExpeditionScreen
## Explicit quality cards; no hidden dropdown or gameplay changes.
signal quality_changed
var _choices: Array[Button]=[]
var _description: Label
const DETAILS := [
	"Lower 3D resolution. No dynamic shadows or snow; fewer distant buildings. Recommended if your phone stutters.",
	"Reduced 3D resolution with lighter shadows and snow. Full miniature detail. Default on phones.",
	"Full 3D resolution, scenery, shadows and snowfall. Best on fast devices."
]


func _ready() -> void:
	build("GRAPHICS QUALITY","Done",navigate_back)
	subtitle.text="Adjust performance without changing rules or saves."
	var col := WorkshopUI.scroll(body)
	for i in GraphicsQuality.NAMES.size():
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel",BattleTheme.panel(Color("203441"),Color("60717b")))
		col.add_child(card)
		var row := WorkshopUI.column(card)
		var b := WorkshopUI.button(row,GraphicsQuality.NAMES[i],_select.bind(i),true)
		_choices.append(b)
		WorkshopUI.label(row,DETAILS[i],24)
	_description=WorkshopUI.label(col,"",22,WorkshopUI.MUTED)


func open() -> void:
	_describe(GraphicsQuality.mode())
	show_screen()


func _select(index: int) -> void:
	GraphicsQuality.select_mode(index)
	_describe(index)
	quality_changed.emit()


func _describe(index: int) -> void:
	for i in _choices.size():
		_choices[i].text=("✓ " if i==index else "")+GraphicsQuality.NAMES[i]
		_choices[i].disabled=i==index
	_description.text="Interface stays sharp. Scenery density updates on the next battlefield."
