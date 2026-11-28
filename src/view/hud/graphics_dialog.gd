class_name GraphicsDialog
extends ExpeditionScreen
## Explicit quality cards; no hidden dropdown or gameplay changes.
signal quality_changed
var _choices: Array[Button]=[]
var _description: Label
var _diagnostics: CheckButton
const DETAILS := [
	"Lower 3D resolution and original low-poly figures. No dynamic shadows or snow; fewer distant buildings. Recommended if your phone stutters.",
	"Reduced 3D resolution with lighter shadows and snow. Enhanced miniature meshes and full-detail dossiers. Default on phones.",
	"Full 3D resolution, highest-detail miniatures, scenery, shadows and snowfall. Best on fast devices."
]


func _ready() -> void:
	build("GRAPHICS QUALITY","Done",navigate_back)
	subtitle.text="Adjust performance without changing rules or saves."
	var col := WorkshopUI.scroll(body)
	for i in GraphicsQuality.NAMES.size():
		var row := WorkshopUI.section_card(col)
		var b := WorkshopUI.button(row,GraphicsQuality.NAMES[i],_select.bind(i),true)
		_choices.append(b)
		WorkshopUI.label(row,DETAILS[i],24)
	_description=WorkshopUI.label(col,"",22,WorkshopUI.MUTED)
	var debug:=WorkshopUI.section_card(col)
	_diagnostics=CheckButton.new()
	_diagnostics.text="Battle performance display"
	_diagnostics.custom_minimum_size.y=64
	debug.add_child(_diagnostics)
	_diagnostics.toggled.connect(GraphicsQuality.set_diagnostics)
	WorkshopUI.label(debug,"Show FPS, frame spikes, draw calls, memory, map load and last AI processing time. No gameplay changes.",22,WorkshopUI.MUTED)


func open() -> void:
	_diagnostics.set_pressed_no_signal(GraphicsQuality.diagnostics())
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
	_description.text="Interface stays sharp. Scenery and miniature mesh detail update on the next battlefield."
