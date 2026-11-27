class_name WarbandSpellbook
extends VBoxContainer
## Inspect legal spell candidates before committing them to one of eight slots.
signal changed

var draft: WarbandDraft
var slot := 0
var candidate := ""
var _split: BoxContainer
var _slots: VBoxContainer
var _choices: ItemList
var _detail: VBoxContainer
var _choice_heading: Label
var _apply_button: Button


func setup(value: WarbandDraft) -> void:
	draft=value
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	WorkshopUI.label(self,"3 home · 3 aligned · 2 distinct neutral schools. Lower casting numbers are easier.",21,WorkshopUI.MUTED)
	_split=BoxContainer.new()
	_split.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_split.add_theme_constant_override("separation",10)
	add_child(_split)
	_slots=WorkshopUI.scroll(_split)
	_slots.get_parent().size_flags_stretch_ratio=1.0
	var choices := WorkshopUI.column(_split)
	choices.size_flags_stretch_ratio=1.0
	_choice_heading=WorkshopUI.label(choices,"",22,WorkshopUI.GOLD)
	_choices=ItemList.new()
	_choices.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_choices.custom_minimum_size.y=125
	_choices.add_theme_font_size_override("font_size",25)
	_choices.add_theme_constant_override("v_separation",18)
	choices.add_child(_choices)
	_choices.item_selected.connect(func(index: int) -> void:
		candidate=str(_choices.get_item_metadata(index))
		_describe())
	var detail_column := WorkshopUI.column(_split)
	detail_column.size_flags_stretch_ratio=1.35
	_detail=WorkshopUI.scroll(detail_column)
	_apply_button=WorkshopUI.button(detail_column,"Choose spell",_apply,true)
	_apply_button.custom_minimum_size.y=70


func reflow(narrow: bool) -> void:
	_split.vertical=narrow


func refresh() -> void:
	select_slot(clampi(slot,0,7))


func select_slot(index: int) -> void:
	slot=index
	WorkshopUI.clear(_slots)
	for i in draft.spells.size():
		var id := draft.spells[i]
		var info: Dictionary=draft.catalog[id]
		var prefix := "Home" if i<3 else ("Aligned" if i<6 else "Neutral")
		var b := WorkshopUI.button(_slots,"%d · %s · TN %d"%( [i+1,info["name"],draft.casting_number(id)] ),select_slot.bind(i),i==slot)
		b.icon=ActionArt.school(str(info["school"]))
		b.add_theme_constant_override("icon_max_width",28)
		b.tooltip_text=prefix
		b.add_theme_font_size_override("font_size",20)
	_choice_heading.text="Home school · +0" if slot<3 else ("Aligned · %s · +2"%str(draft.schools[draft.school]["aligned"][slot-3]).capitalize() if slot<6 else "Neutral school · +4")
	_choices.clear()
	candidate=draft.spells[slot]
	for id in draft.candidates(slot):
		var info: Dictionary=draft.catalog[id]
		_choices.add_item("%s · %d"%[info["name"],draft.casting_number(id)],ActionArt.school(str(info["school"])))
		_choices.set_item_metadata(_choices.item_count-1,id)
		if candidate==id:
			_choices.select(_choices.item_count-1)
	_describe()


func _conflict(id: String) -> bool:
	for i in draft.spells.size():
		if i==slot:
			continue
		var other := draft.spells[i]
		if other==id or (slot>=6 and i>=6 and draft.catalog[other]["school"]==draft.catalog[id]["school"]):
			return true
	return false


func _describe() -> void:
	WorkshopUI.clear(_detail)
	var info: Dictionary=draft.catalog[candidate]
	var tn := draft.casting_number(candidate)
	WorkshopUI.label(_detail,str(info["name"]),32,WorkshopUI.GOLD)
	WorkshopUI.label(_detail,"%s · Casting number %d"%[str(info["school"]).capitalize(),tn],24)
	WorkshopUI.label(_detail,"WIZARD %d%%   /   APPRENTICE %d%%"%[clampi(21-tn,0,20)*5,clampi(19-tn,0,20)*5],25,Color("a7d6da"))
	WorkshopUI.label(_detail,"Base TN %d + school adjustment %d"%[info["number"],tn-int(info["number"])],22,WorkshopUI.MUTED)
	SpellReference.append_details(_detail,candidate)
	if info["kind"]=="unimplemented":
		WorkshopUI.label(_detail,"Not available in digital combat yet.",20,Color("edaa91"))
	var conflict := _conflict(candidate)
	if conflict:
		WorkshopUI.label(_detail,"Already selected, or conflicts with the other neutral school.",20,Color("edaa91"))
	_apply_button.text="Equipped in this slot" if candidate==draft.spells[slot] else "Choose spell for slot %d"%(slot+1)
	_apply_button.disabled=conflict or candidate==draft.spells[slot]


func _apply() -> void:
	if not draft.candidates(slot).has(candidate) or _conflict(candidate):
		return
	draft.spells[slot]=candidate
	changed.emit()
	select_slot(slot)
