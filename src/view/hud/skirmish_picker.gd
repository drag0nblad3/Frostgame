class_name SkirmishPicker
extends ExpeditionScreen
## Full-height scenario catalogue. Inspect one battlefield before explicitly launching.
signal selected(id: String)
signal edit_requested

var _list: ItemList
var _entries := {}
var _ids: Array[String]=[]
var _chosen := ""
var _from_home := false
var _split: BoxContainer
var _map: ScenarioMapPreview
var _table: ScenarioTablePreview
var _detail: VBoxContainer
var _name: Label
var _category: Label
var _edit: Button
var _filter: OptionButton
var _terrain: TerrainDb
var _boards := {}
var _board_order: Array[String]=[]
var _scenarios := {}
var _roster := {}


func _ready() -> void:
	build("CHOOSE BATTLEFIELD","Start skirmish",_start)
	var row := HBoxContainer.new()
	body.add_child(row)
	_filter=OptionButton.new()
	_filter.add_item("All battlefields")
	_filter.add_item("Core scenarios")
	_filter.add_item("The Red King")
	_filter.custom_minimum_size.y=56
	_filter.add_theme_font_size_override("font_size",23)
	_filter.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(_filter)
	_filter.item_selected.connect(func(_i: int) -> void: _populate())
	_edit=WorkshopUI.button(row,"Edit warband",func() -> void:
		hide()
		edit_requested.emit())
	_split=BoxContainer.new()
	_split.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_split.add_theme_constant_override("separation",12)
	body.add_child(_split)
	_list=ItemList.new()
	_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_list.size_flags_stretch_ratio=0.9
	_list.custom_minimum_size.y=130
	_list.add_theme_font_size_override("font_size",25)
	_list.add_theme_constant_override("v_separation",20)
	_split.add_child(_list)
	_list.item_selected.connect(_inspect)
	var visual := WorkshopUI.column(_split)
	visual.size_flags_stretch_ratio=1.7
	_category=WorkshopUI.label(visual,"",18,WorkshopUI.GOLD)
	_name=WorkshopUI.label(visual,"",30)
	WorkshopUI.label(visual,"TACTICAL TERRAIN · SCHEMATIC",16,WorkshopUI.MUTED)
	_table=ScenarioTablePreview.new()
	_table.custom_minimum_size.y=170
	_table.size_flags_vertical=Control.SIZE_EXPAND_FILL
	visual.add_child(_table)
	_map=ScenarioMapPreview.new()
	_map.custom_minimum_size.y=120
	_map.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_map.size_flags_stretch_ratio=0.7
	visual.add_child(_map)
	_detail=WorkshopUI.scroll(_split)
	_detail.get_parent().size_flags_stretch_ratio=1.15


func open(from_home: bool=false) -> void:
	_from_home=from_home
	_edit.visible=from_home
	_filter.set_item_disabled(2,not WarbandSlots.content_profile().enabled.has("red_king"))
	if _filter.is_item_disabled(_filter.selected):
		_filter.select(0)
	_entries=ScenarioBriefing.available_entries(WarbandSlots.content_profile())
	_roster=WarbandSlots.roster()
	_populate()
	show_screen()


func _reflow() -> void:
	if _split!=null:
		_split.vertical=size.x<size.y


func _populate() -> void:
	_list.clear()
	_ids.clear()
	for id: String in _entries:
		var red := id.begins_with("red_king_")
		if (_filter.selected==1 and red) or (_filter.selected==2 and not red):
			continue
		_ids.append(id)
		_list.add_item(str(_entries[id][0]))
	if _ids.is_empty():
		action.disabled=true
		return
	var index := maxi(0,_ids.find(_chosen))
	_list.select(index)
	_inspect(index)


func _inspect(index: int) -> void:
	_chosen=_ids[index]
	var entry: Array=_entries[_chosen]
	if not _scenarios.has(_chosen):
		_scenarios[_chosen]=JsonFile.read(ScenarioLoader.DIR+_chosen+".json")
	var data: Dictionary=_scenarios[_chosen]
	var board := _preview_board(str(data["board"]))
	_name.text=str(entry[0])
	_category.text="THE RED KING · EXPANSION" if _chosen.begins_with("red_king_") else "CORE · SKIRMISH"
	_table.setup(board)
	_map.setup_scenario(data,board)
	WorkshopUI.clear(_detail)
	WorkshopUI.label(_detail,"OBJECTIVE",18,WorkshopUI.GOLD)
	WorkshopUI.label(_detail,str(entry[1]),26)
	WorkshopUI.label(_detail,"BATTLEFIELD RULES",18,WorkshopUI.GOLD)
	WorkshopUI.label(_detail,str(entry[2]),24)
	WorkshopUI.label(_detail,"EXPEDITION",18,WorkshopUI.GOLD)
	var roster := _roster
	if roster.is_empty():
		var bands: Array=data.get("warbands",[])
		var fallback: Dictionary=bands[0] if not bands.is_empty() else {}
		WorkshopUI.label(_detail,"Scenario's preset warband · %s"%fallback.get("name","Default"),23)
	else:
		WorkshopUI.label(_detail,"%s · %d members"%[roster.get("name","Warband"),roster.get("figures",[]).size()],24)
	WorkshopUI.label(_detail,"%d″ × %d″ board · %d initial treasure markers"%[board.size.x,board.size.y,data.get("treasures",[]).size()],21,WorkshopUI.MUTED)
	WorkshopUI.label(_detail,"Gold dots show initial treasure locations. Special objectives may change during play.",19,WorkshopUI.MUTED)
	subtitle.text="Standalone battle · Campaign progression is unchanged." if _from_home else "Starting a new battle replaces unsaved progress."
	action.text="Start "+str(entry[0])
	action.disabled=false


## Read-only preview boards are separate from the active battle. Bound the
## cache because BoardLoader also allocates movement lattice arrays.
func _preview_board(id: String) -> Board:
	if _terrain==null:
		_terrain=TerrainDb.load_file()
	if not _boards.has(id):
		_boards[id]=BoardLoader.load_id(id,_terrain)
	_board_order.erase(id)
	_board_order.append(id)
	if _board_order.size()>4:
		_boards.erase(_board_order.pop_front())
	return _boards[id]


func _start() -> void:
	if not _ids.has(_chosen):
		return
	hide()
	selected.emit(_chosen)
