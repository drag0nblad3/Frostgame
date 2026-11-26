class_name SkirmishPicker
extends AcceptDialog
## Scrollable scenario chooser with real schematic terrain previews.
signal selected(id: String,layered: bool)
var _list: VBoxContainer
var _scroll: ScrollContainer
var _mode: OptionButton
var _from_home := false
var _context: Label
const LAYERED := {"stacked_gatehouse":["Stacked Gatehouse","Two overlapping levels with stairs and bridges. Fixed experimental warbands."],"layered_silent_tower":["Silent Tower · multi-floor","Three tower elevations and null-magic zones. Fixed experimental warbands."]}


func _ready() -> void:
	title="Choose battlefield"
	theme=BattleTheme.create()
	exclusive=true
	get_ok_button().text="Cancel"
	var col := VBoxContainer.new()
	add_child(col)
	_mode=OptionButton.new()
	_mode.add_item("Standard skirmishes")
	_mode.add_item("Experimental multi-floor")
	_mode.item_selected.connect(func(_i: int) -> void:_populate())
	col.add_child(_mode)
	_context=Label.new()
	_context.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_context)
	_scroll=ScrollContainer.new()
	_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(_scroll)
	_list=VBoxContainer.new()
	_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation",8)
	_scroll.add_child(_list)


func open(experimental: bool=false,from_home: bool=false) -> void:
	_from_home=from_home
	var viewport := get_parent().get_viewport().get_visible_rect().size
	_scroll.custom_minimum_size=Vector2(minf(760,viewport.x*0.85),minf(490,viewport.y*0.70))
	_mode.select(1 if experimental else 0)
	_populate()
	popup_centered()


func _populate() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var layered := _mode.selected==1
	_context.text="Prototype battles use fixed test warbands, not your saved recruits." if layered else ("Using %s."%WarbandSlots.roster().get("name","the default expedition"))
	if not _from_home:
		_context.text+=" Starting a new battle replaces unsaved progress."
	if layered:
		for id: String in LAYERED:
			_card(id,LAYERED[id][0],LAYERED[id][1],id,true)
	else:
		for id: String in ScenarioBriefing.ENTRIES:
			var entry: Array=ScenarioBriefing.ENTRIES[id]
			var data: Dictionary=JsonFile.read(ScenarioLoader.DIR+id+".json")
			_card(id,entry[0],entry[1]+"\n"+entry[2],str(data["board"]),false)
	_scroll.scroll_vertical=0


func _card(id: String,label: String,description: String,board: String,layered: bool) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",BattleTheme.panel(Color("202e38"),Color("657980"),3))
	_list.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	panel.add_child(row)
	var preview := ScenarioMapPreview.new()
	preview.custom_minimum_size=Vector2(110,110)
	preview.setup(board)
	row.add_child(preview)
	var col := VBoxContainer.new()
	col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var heading := Label.new()
	heading.text=label
	heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size",21)
	col.add_child(heading)
	var detail := Label.new()
	detail.text=description
	detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size",15)
	col.add_child(detail)
	var button := Button.new()
	button.text="Start skirmish" if _from_home else "Choose"
	button.custom_minimum_size.y=42
	button.pressed.connect(func() -> void:
		hide()
		selected.emit(id,layered))
	col.add_child(button)
