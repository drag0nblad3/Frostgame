class_name WarbandInspector
extends VBoxContainer
## Full-height miniature and readable dossier. Choices use the existing draft limits.
signal changed
signal back
signal spells

var draft: WarbandDraft
var slot := 0
var portrait: MiniaturePortrait
var _split: BoxContainer
var _visual: VBoxContainer
var _detail: VBoxContainer
var _chooser: VBoxContainer
var _selection: ItemList
var _candidate := ""
var _filter := "All"
var _title: Label
var _tag: Label


func setup(value: WarbandDraft) -> void:
	draft=value
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	_split=BoxContainer.new()
	_split.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_split.add_theme_constant_override("separation",12)
	add_child(_split)
	_visual=WorkshopUI.column(_split)
	_visual.size_flags_stretch_ratio=1.35
	_title=WorkshopUI.label(_visual,"",30,WorkshopUI.GOLD)
	_tag=WorkshopUI.label(_visual,"",20,WorkshopUI.MUTED)
	portrait=MiniaturePortrait.new()
	portrait.tight_frame=true
	portrait.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	portrait.size_flags_vertical=Control.SIZE_EXPAND_FILL
	portrait.custom_minimum_size=Vector2(0,200)
	_visual.add_child(portrait)
	WorkshopUI.label(_visual,"Drag to rotate miniature",18,WorkshopUI.MUTED).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_detail=WorkshopUI.scroll(_split)
	_detail.get_parent().size_flags_stretch_ratio=1.2
	_chooser=WorkshopUI.column(_split)
	_chooser.size_flags_stretch_ratio=0.86


func reflow(narrow: bool) -> void:
	_split.vertical=narrow
	portrait.custom_minimum_size.y=200 if narrow else 120
	_visual.size_flags_stretch_ratio=1.3 if narrow else 1.35
	_chooser.size_flags_stretch_ratio=0.8


func inspect(index: int) -> void:
	slot=index
	_filter="All"
	_candidate=""
	if slot>=2 and slot-2>=draft.soldiers.size():
		_candidate="thug"
	_build_choices()
	_refresh_detail()


func _hiring() -> bool:
	return slot>=2 and slot-2>=draft.soldiers.size()


func _build_choices() -> void:
	WorkshopUI.clear(_chooser)
	_chooser.visible=slot==0 or _hiring()
	if not _chooser.visible:
		return
	WorkshopUI.label(_chooser,"MAGIC SCHOOLS" if slot==0 else "RECRUIT CATALOGUE",19,WorkshopUI.GOLD)
	if _hiring():
		var filters := HFlowContainer.new()
		_chooser.add_child(filters)
		for name in ["All","Standard","Specialist","Affordable"]:
			var button := WorkshopUI.button(filters,name,_set_filter.bind(name))
			button.add_theme_font_size_override("font_size",18)
			button.disabled=name==_filter
	_selection=ItemList.new()
	_selection.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_selection.custom_minimum_size.y=130
	_selection.add_theme_font_size_override("font_size",22)
	_selection.add_theme_constant_override("v_separation",17)
	_chooser.add_child(_selection)
	if slot==0:
		for id: String in draft.schools:
			_selection.add_item(id.capitalize(),ActionArt.school(id))
			_selection.set_item_metadata(_selection.item_count-1,id)
			if id==draft.school:
				_selection.select(_selection.item_count-1)
	else:
		for id: String in draft.db.figures:
			var d := draft.db.get_def(id)
			if d.role!="soldier" or not draft.db.available(id):
				continue
			if (_filter=="Standard" and d.specialist) or (_filter=="Specialist" and not d.specialist) or (_filter=="Affordable" and not draft.can_hire(id)):
				continue
			_selection.add_item("%s  ·  %d gc"%[d.name,d.cost])
			_selection.set_item_metadata(_selection.item_count-1,id)
			if id==_candidate:
				_selection.select(_selection.item_count-1)
		if _selection.item_count>0 and _selection.get_selected_items().is_empty():
			_selection.select(0)
			_candidate=str(_selection.get_item_metadata(0))
	_selection.item_selected.connect(_choose)


func _set_filter(value: String) -> void:
	_filter=value
	_build_choices()
	_refresh_detail()


func _choose(index: int) -> void:
	var id := str(_selection.get_item_metadata(index))
	if slot==0:
		if draft.school!=id:
			draft.school=id
			draft.choose_defaults()
			changed.emit()
	else:
		_candidate=id
	_refresh_detail()


func _refresh_detail() -> void:
	WorkshopUI.clear(_detail)
	var caster := slot<2
	var hiring := _hiring()
	var f: Figure
	if hiring:
		if _candidate.is_empty() or not draft.db.available(_candidate):
			_title.text="No recruits match"
			return
		f=Figure.new(0,draft.db.get_def(_candidate),0,Vector2.ZERO,draft.db.unarmed())
	else:
		f=WorkshopUI.figure(draft,slot)
	var d := f.def
	_title.text=draft.wizard_name if slot==0 else d.name
	_tag.text=draft.school.capitalize() if caster else ("%d gc  ·  %s"%[d.cost,"Specialist" if d.specialist else "Standard soldier"])
	portrait.set_figure(f,FigureView.SIDE_COLORS[0],draft.school if caster else "")
	WorkshopUI.stats(_detail,d)
	if caster:
		WarbandCasterEditor.build(self,_detail)
	else:
		WorkshopUI.label(_detail,"BATTLEFIELD ROLE",17,WorkshopUI.GOLD)
		WorkshopUI.label(_detail,WarbandAdvice.ROLES.get(d.id,"A warband soldier."),23)
		WorkshopUI.label(_detail,"EQUIPMENT",17,WorkshopUI.GOLD)
		WorkshopUI.label(_detail,WarbandAdvice.loadout(d)+(" Shield included." if d.shield else ""),22)
		if hiring:
			var reason := WarbandAdvice.hire_reason(draft,d)
			var b := WorkshopUI.button(_detail,"Hire %s · %d gc"%[d.name,d.cost],_hire,true)
			b.disabled=not draft.can_hire(d.id)
			if not reason.is_empty():
				WorkshopUI.label(_detail,reason,20,Color("edaa91"))
		else:
			WorkshopUI.button(_detail,"Remove from warband",_remove)


func _hire() -> void:
	if draft.hire(_candidate):
		slot=draft.soldiers.size()+1
		changed.emit()
		back.emit()


func _remove() -> void:
	if slot>=2 and slot-2<draft.soldiers.size():
		draft.soldiers.remove_at(slot-2)
		changed.emit()
		back.emit()
