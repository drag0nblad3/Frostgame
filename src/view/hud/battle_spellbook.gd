class_name BattleSpellbook
extends ExpeditionScreen
## Inspect a spell without rolling or spending an action; select only legal entries.
signal chosen(key: String)
signal cancelled

var _entries: Array[Dictionary]=[]
var _split: BoxContainer
var _list: ItemList
var _detail: VBoxContainer
var _selected := -1


func _ready() -> void:
	build("CASTING SPELLBOOK","Choose target ›",_choose)
	_split=BoxContainer.new()
	_split.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_split.add_theme_constant_override("separation",12)
	body.add_child(_split)
	_list=ItemList.new()
	_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_list.size_flags_stretch_ratio=1.0
	_list.custom_minimum_size.y=140
	_list.add_theme_font_size_override("font_size",25)
	_list.add_theme_constant_override("v_separation",17)
	_split.add_child(_list)
	_list.item_selected.connect(_inspect)
	_detail=WorkshopUI.scroll(_split)
	_detail.get_parent().size_flags_stretch_ratio=1.8


func open(caster: String,entries: Array[Dictionary]) -> void:
	_entries=entries
	_list.clear()
	_selected=-1
	WorkshopUI.clear(_detail)
	subtitle.text=caster+" · Inspect first, then choose a target. No action is spent yet."
	action.disabled=true
	for e in entries:
		var label_text := str(e["name"])+" · "+("TN %d"%e["tn"] if e["known"] else "Scroll")
		if not e["legal"]:
			label_text+=" · Unavailable"
		_list.add_item(label_text,ActionArt.school(str(e["school"])))
		var i := _list.item_count-1
		if not e["legal"]:
			_list.set_item_custom_fg_color(i,WorkshopUI.MUTED)
		elif _selected<0:
			_selected=i
	if not entries.is_empty():
		_selected=maxi(0,_selected)
		_list.select(_selected)
		_inspect(_selected)
	show_screen()


func _inspect(index: int) -> void:
	_selected=index
	var e := _entries[index]
	WorkshopUI.clear(_detail)
	WorkshopUI.label(_detail,str(e["name"]),34,WorkshopUI.GOLD)
	WorkshopUI.label(_detail,str(e["school"]).capitalize(),22,WorkshopUI.MUTED)
	if e["known"]:
		WorkshopUI.label(_detail,"TN %d · %d%% before current situational modifiers or empowerment"%[e["tn"],e["chance"]],25,Color("a7d6da"))
	else:
		WorkshopUI.label(_detail,"Scroll cast · consumes the scroll; no Health empowerment.",24,Color("a7d6da"))
	if not e["legal"]:
		WorkshopUI.label(_detail,"Campaign preparation/aftermath only." if e["ritual_only"] else "Not currently castable: no eligible target, location or other requirement is met.",22,Color("edaa91"))
	if e["key"]=="enchant_ammo":
		WorkshopUI.label(_detail,"This variant enchants ammunition rather than the weapon itself.",24)
	SpellReference.append_details(_detail,str(e["id"]))
	action.disabled=not e["legal"]


func _choose() -> void:
	if _selected<0 or not _entries[_selected]["legal"]:
		return
	var key := str(_entries[_selected]["key"])
	hide()
	chosen.emit("spell_"+key)


func navigate_back() -> void:
	hide()
	cancelled.emit()


func _reflow() -> void:
	if _split!=null:
		_split.vertical=size.x<size.y
