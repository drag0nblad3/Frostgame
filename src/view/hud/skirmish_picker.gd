class_name SkirmishPicker
extends AcceptDialog
## Scrollable scenario chooser with real schematic terrain previews.
signal selected(id: String)
var _list: VBoxContainer
var _scroll: ScrollContainer
var _from_home := false
var _context: Label


func _ready() -> void:
	title="Choose battlefield"
	theme=BattleTheme.create()
	exclusive=true
	get_ok_button().text="Cancel"
	var col := VBoxContainer.new()
	add_child(col)
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


func open(from_home: bool=false) -> void:
	_from_home=from_home
	var viewport := PhoneSafeArea.safe_rect(get_parent().get_viewport(),14).size
	_scroll.custom_minimum_size=Vector2(minf(760,viewport.x*0.88),minf(490,viewport.y*0.67))
	_populate()
	PhoneSafeArea.popup_dialog(self)


func _populate() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_context.text="Using %s."%WarbandSlots.roster().get("name","the default expedition")
	if not _from_home:
		_context.text+=" Starting a new battle replaces unsaved progress."
	for id: String in ScenarioBriefing.ENTRIES:
		var entry: Array=ScenarioBriefing.ENTRIES[id]
		var data: Dictionary=JsonFile.read(ScenarioLoader.DIR+id+".json")
		_card(id,entry[0],entry[1]+"\n"+entry[2],str(data["board"]))
	_scroll.scroll_vertical=0


func _card(id: String,label: String,description: String,board: String) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",BattleTheme.panel(Color("202e38"),Color("657980"),3))
	_list.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	panel.add_child(row)
	var preview := ScenarioMapPreview.new()
	preview.custom_minimum_size=Vector2(100,100)
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
	detail.add_theme_font_size_override("font_size",18)
	col.add_child(detail)
	var button := Button.new()
	button.text="Start skirmish" if _from_home else "Choose"
	button.custom_minimum_size.y=52
	button.pressed.connect(func() -> void:
		hide()
		selected.emit(id))
	col.add_child(button)
