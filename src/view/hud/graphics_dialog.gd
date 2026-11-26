class_name GraphicsDialog
extends AcceptDialog
## Readable, phone-safe quality selection.
signal quality_changed
var _choice: OptionButton
var _description: Label


func _ready() -> void:
	title="Graphics quality"
	theme=BattleTheme.create()
	exclusive=true
	get_ok_button().text="Done"
	var col := VBoxContainer.new()
	add_child(col)
	_choice=OptionButton.new()
	_choice.custom_minimum_size.y=52
	for label: String in GraphicsQuality.NAMES:
		_choice.add_item(label)
	col.add_child(_choice)
	_description=Label.new()
	_description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_description)
	_choice.item_selected.connect(func(index: int) -> void:
		GraphicsQuality.select_mode(index)
		_describe(index)
		quality_changed.emit())


func open() -> void:
	var safe := PhoneSafeArea.safe_rect(get_parent().get_viewport(),14).size
	_description.custom_minimum_size.x=minf(500,safe.x*0.8)
	_choice.select(GraphicsQuality.mode())
	_describe(GraphicsQuality.mode())
	PhoneSafeArea.popup_dialog(self)


func _describe(index: int) -> void:
	var detail: String = ["Lower 3D resolution; no dynamic shadows or snow; fewer background buildings. Recommended if your phone stutters.","Reduced 3D resolution, lighter shadows and snow; full miniature detail. Default on phones.","Full 3D resolution, full scenery, shadows and snowfall. Best on fast devices."][index]
	_description.text=detail+"\n\nText and interface stay sharp. No rules or saves change. Scenery density updates on the next battlefield."
