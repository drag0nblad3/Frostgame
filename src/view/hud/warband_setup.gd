class_name WarbandSetup
extends AcceptDialog
## Compact warband editor: fixed decision panels, scroll only inside long lists.
signal drafted(roster: Dictionary)

var draft: WarbandDraft
var _spell_rows: GridContainer
var _spell_slots: Array[Button]=[]
var _spell_choice: OptionButton
var _spell_detail: RichTextLabel
var _spell_title: Label
var _active_slot := 0
var _recruits: OptionButton
var _roster: ItemList
var _summary: Label
var _name: LineEdit
var _school: OptionButton
var _apprentice: CheckBox
var _hire: Button
var _recruit_portrait: MiniaturePortrait
var _recruit_info: Label
var _wizard_portrait: MiniaturePortrait
var _school_info: Label
var _wizard_stats: Label
var _apprentice_loadout: OptionButton
var _wizard_loadout: OptionButton
var _loadout_info: Label
var _recruit_warning: Label
var _tabs: TabContainer


func setup(db: FigureDb,saved: Dictionary={}) -> void:
	draft=WarbandDraft.new(db)
	draft.choose_defaults()
	if not saved.is_empty():
		draft.restore_roster(saved)
	theme=BattleTheme.create()
	title="Create a wizard and warband"
	get_ok_button().text="Begin skirmish"
	dialog_hide_on_ok=false
	var bounds := PhoneSafeArea.safe_rect(get_parent().get_viewport(),14).size
	var frame := VBoxContainer.new()
	add_child(frame)
	_summary=_label(frame,"",18)
	_tabs=TabContainer.new()
	_tabs.custom_minimum_size=Vector2(minf(1050,bounds.x*0.90),minf(470,bounds.y*0.60))
	frame.add_child(_tabs)
	var wizard := _page("1 · Wizard")
	var spells := _page("2 · Spells")
	var recruits := _page("3 · Recruits")
	_build_wizard(wizard,bounds)
	_build_spells(spells)
	_build_recruits(recruits,bounds)
	add_cancel_button("Back")
	confirmed.connect(_confirm)
	_rebuild_spells()
	_update()


func _page(label: String) -> VBoxContainer:
	# Auto hides overflow controls when all content fits. No forced outer scroll.
	var scroll := ScrollContainer.new()
	scroll.name=label
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	_tabs.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",6)
	scroll.add_child(body)
	return body


func _label(parent: Node,value: String,font: int=18) -> Label:
	var label := Label.new()
	label.text=value
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font)
	parent.add_child(label)
	return label


func _column(parent: Node) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(col)
	return col


func _option(parent: Node) -> OptionButton:
	var choice := OptionButton.new()
	choice.fit_to_longest_item=false
	choice.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	choice.custom_minimum_size.y=44
	choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(choice)
	return choice


func _build_wizard(body: VBoxContainer,bounds: Vector2) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	body.add_child(row)
	var preview := VBoxContainer.new()
	row.add_child(preview)
	_wizard_portrait=MiniaturePortrait.new()
	_wizard_portrait.custom_minimum_size=Vector2(minf(265,bounds.x*0.28),minf(285,bounds.y*0.42))
	preview.add_child(_wizard_portrait)
	_label(preview,"Drag to rotate",16)
	var controls := _column(row)
	_name=LineEdit.new()
	_name.placeholder_text="Wizard name"
	_name.text=draft.wizard_name
	_name.custom_minimum_size.y=44
	controls.add_child(_name)
	_name.text_changed.connect(func(value: String) -> void:
		draft.wizard_name=value
		_update_summary())
	_school=_option(controls)
	for id: String in draft.schools:
		_school.add_icon_item(ActionArt.school(id),id.capitalize())
		_school.set_item_metadata(_school.item_count-1,id)
		if id==draft.school:
			_school.select(_school.item_count-1)
	_school.add_theme_constant_override("icon_max_width",32)
	_school.item_selected.connect(_change_school)
	_school_info=_label(controls,"")
	_wizard_stats=_label(controls,"",16)
	_apprentice=CheckBox.new()
	_apprentice.text="Hire apprentice (100 gc)"
	_apprentice.button_pressed=draft.apprentice
	_apprentice.custom_minimum_size.y=44
	controls.add_child(_apprentice)
	_apprentice.toggled.connect(func(on: bool) -> void:
		draft.apprentice=on
		_update())
	_label(controls,"Second caster acts in the Apprentice phase; uses the same spellbook at +2 casting difficulty.",16)
	var loadouts := GridContainer.new()
	loadouts.columns=2
	loadouts.add_theme_constant_override("h_separation",12)
	body.add_child(loadouts)
	_wizard_loadout=_add_loadout(_column(loadouts),"Wizard equipment (5 slots)",false)
	_apprentice_loadout=_add_loadout(_column(loadouts),"Apprentice equipment (4 slots)",true)
	_loadout_info=_label(body,"",16)


func _build_spells(body: VBoxContainer) -> void:
	_label(body,"Choose 3 home-school spells, 1 from each aligned school, and 2 from different neutral schools. Lower TN is easier.",16)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	body.add_child(row)
	_spell_rows=GridContainer.new()
	_spell_rows.columns=2
	_spell_rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_spell_rows.add_theme_constant_override("h_separation",6)
	_spell_rows.add_theme_constant_override("v_separation",6)
	row.add_child(_spell_rows)
	for i in 8:
		var button := Button.new()
		button.custom_minimum_size=Vector2(100,60)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.toggle_mode=true
		button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		_spell_rows.add_child(button)
		_spell_slots.append(button)
		button.pressed.connect(_show_spell.bind(i))
	var details := _column(row)
	_spell_title=_label(details,"",18)
	_spell_choice=_option(details)
	_spell_choice.add_theme_constant_override("icon_max_width",28)
	_spell_choice.item_selected.connect(func(index: int) -> void:
		draft.spells[_active_slot]=str(_spell_choice.get_item_metadata(index))
		_rebuild_spells()
		_update_summary())
	_spell_detail=RichTextLabel.new()
	_spell_detail.fit_content=false
	_spell_detail.scroll_active=true
	_spell_detail.custom_minimum_size=Vector2(0,180)
	_spell_detail.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_spell_detail.add_theme_font_size_override("normal_font_size",18)
	details.add_child(_spell_detail)


func _build_recruits(body: VBoxContainer,bounds: Vector2) -> void:
	_label(body,"Up to eight soldiers, including four specialists. Free recruits help fill the warband without spending gold.",16)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	body.add_child(row)
	var recruit := _column(row)
	var choose := HBoxContainer.new()
	recruit.add_child(choose)
	_recruits=_option(choose)
	for id: String in draft.db.figures:
		var d := draft.db.get_def(id)
		if d.role=="soldier" and draft.db.available(id):
			_recruits.add_item("%s · %d gc"%[d.name,d.cost])
			_recruits.set_item_metadata(_recruits.item_count-1,id)
	_recruits.item_selected.connect(func(_i: int) -> void:_update())
	_hire=Button.new()
	_hire.text="Hire"
	_hire.custom_minimum_size=Vector2(84,44)
	choose.add_child(_hire)
	_hire.pressed.connect(func() -> void:
		draft.hire(str(_recruits.get_selected_metadata()))
		_update())
	var card := HBoxContainer.new()
	recruit.add_child(card)
	_recruit_portrait=MiniaturePortrait.new()
	_recruit_portrait.custom_minimum_size=Vector2(minf(175,bounds.x*0.19),minf(225,bounds.y*0.34))
	card.add_child(_recruit_portrait)
	_recruit_info=_label(card,"",16)
	_recruit_info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_recruit_warning=_label(recruit,"",16)
	_recruit_warning.modulate=Color("e3ae8d")
	var roster := _column(row)
	_label(roster,"YOUR SOLDIERS",18)
	_roster=ItemList.new()
	_roster.custom_minimum_size.y=170
	_roster.size_flags_vertical=Control.SIZE_EXPAND_FILL
	roster.add_child(_roster)
	var remove := Button.new()
	remove.text="Remove selected"
	remove.custom_minimum_size.y=44
	roster.add_child(remove)
	remove.pressed.connect(func() -> void:
		var selected := _roster.get_selected_items()
		if not selected.is_empty():
			draft.soldiers.remove_at(selected[0])
			_update())
	var fill := Button.new()
	fill.text="Fill with free recruits"
	fill.custom_minimum_size.y=44
	roster.add_child(fill)
	fill.pressed.connect(func() -> void:
		while draft.can_hire("thug"):
			if not draft.hire("thug"):
				break
		_update())


func _change_school(index: int) -> void:
	draft.school=str(_school.get_item_metadata(index))
	draft.choose_defaults()
	_active_slot=0
	_rebuild_spells()
	_update()


func _rebuild_spells() -> void:
	for slot in 8:
		var id := draft.spells[slot]
		var info: Dictionary=draft.catalog[id]
		_spell_slots[slot].text="%d · %s\nTN %d"%[slot+1,info["name"],draft.casting_number(id)]
		_spell_slots[slot].icon=ActionArt.school(str(info["school"]))
		_spell_slots[slot].add_theme_constant_override("icon_max_width",24)
	_show_spell(_active_slot)


func _show_spell(slot: int) -> void:
	_active_slot=slot
	for i in _spell_slots.size():
		_spell_slots[i].set_pressed_no_signal(i==slot)
	_spell_title.text="Home school · +0" if slot<3 else ("Aligned: %s · +2"%str(draft.schools[draft.school]["aligned"][slot-3]).capitalize() if slot<6 else "Neutral school · +4")
	_spell_choice.clear()
	for id in draft.candidates(slot):
		var info: Dictionary=draft.catalog[id]
		_spell_choice.add_icon_item(ActionArt.school(str(info["school"])),"%s · TN %d"%[info["name"],draft.casting_number(id)])
		var i := _spell_choice.item_count-1
		_spell_choice.set_item_metadata(i,id)
		_spell_choice.set_item_disabled(i,_spell_conflict(slot,id))
		if draft.spells[slot]==id:
			_spell_choice.select(i)
	var chosen := draft.spells[slot]
	_spell_detail.text=WarbandAdvice.spell(draft,chosen)
	_spell_detail.scroll_to_line(0)


func _update_summary() -> void:
	var problems := draft.errors()
	var live := 0
	for id in draft.spells:
		if draft.catalog[id]["kind"]!="unimplemented" or Rituals.BEFORE.has(id) or Rituals.AFTER.has(id):
			live+=1
	_summary.text="%d / %d gc left   •   %d/8 soldiers   •   %d/4 specialists   •   %d/8 available spells"%[WarbandDraft.BUDGET-draft.cost(),WarbandDraft.BUDGET,draft.soldiers.size(),draft.specialists(),live]
	if not problems.is_empty():
		_summary.text+="\n"+"; ".join(problems)
	_summary.modulate=Color("a4d3b0") if problems.is_empty() else Color("e3ae8d")
	get_ok_button().disabled=not problems.is_empty()


func _update() -> void:
	_update_summary()
	var wizard_def := CasterLoadout.definition(draft.db.get_def("wizard"),draft.wizard_weapons,draft.db)
	_wizard_portrait.set_figure(Figure.new(0,wizard_def,0,Vector2.ZERO,draft.db.unarmed()),FigureView.SIDE_COLORS[0],draft.school)
	_school_info.text=WarbandAdvice.school(draft)
	_wizard_stats.text=WarbandAdvice.stats(wizard_def)
	_apprentice.disabled=not draft.apprentice and draft.cost()+draft.db.get_def("apprentice").cost>WarbandDraft.BUDGET
	_apprentice_loadout.disabled=not draft.apprentice
	_loadout_info.text=WarbandAdvice.loadout(wizard_def)+"\n"+("Apprentice: "+WarbandAdvice.loadout(CasterLoadout.definition(draft.db.get_def("apprentice"),draft.apprentice_weapons,draft.db)) if draft.apprentice else "No apprentice hired.")
	_roster.clear()
	for id in draft.soldiers:
		var d := draft.db.get_def(id)
		_roster.add_item("%s · %d gc%s"%[d.name,d.cost," · S" if d.specialist else ""])
	var recruit_id := str(_recruits.get_selected_metadata())
	var definition := draft.db.get_def(recruit_id)
	# Keep unaffordable candidates inspectable; explain why Hire is disabled.
	_hire.disabled=not draft.can_hire(recruit_id)
	if definition!=null:
		_recruit_portrait.set_figure(Figure.new(0,definition,0,Vector2.ZERO,draft.db.unarmed()),FigureView.SIDE_COLORS[0])
		_recruit_info.text=WarbandAdvice.recruit(definition)
		_recruit_warning.text=WarbandAdvice.hire_reason(draft,definition)


func _confirm() -> void:
	if not draft.errors().is_empty():
		return
	drafted.emit(draft.as_warband())
	hide()


func _add_loadout(body: VBoxContainer,label: String,for_apprentice: bool) -> OptionButton:
	_label(body,label,16)
	var choice := _option(body)
	for preset: String in CasterLoadout.PRESETS:
		var weapons: Array=CasterLoadout.PRESETS[preset]
		choice.add_item("%s · %d slots"%[preset,CasterLoadout.weapon_slots(weapons)])
		choice.set_item_metadata(choice.item_count-1,preset)
		if weapons==(draft.apprentice_weapons if for_apprentice else draft.wizard_weapons):
			choice.select(choice.item_count-1)
	choice.item_selected.connect(func(index: int) -> void:
		var weapons: Array=CasterLoadout.PRESETS[choice.get_item_metadata(index)]
		if for_apprentice:
			draft.apprentice_weapons=weapons.duplicate()
		else:
			draft.wizard_weapons=weapons.duplicate()
		_update())
	return choice


func _spell_conflict(slot: int,id: String) -> bool:
	for i in draft.spells.size():
		if i==slot:
			continue
		var other := draft.spells[i]
		if other==id or (slot>=6 and i>=6 and draft.catalog[id]["school"]==draft.catalog[other]["school"]):
			return true
	return false
