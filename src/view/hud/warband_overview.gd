class_name WarbandOverview
extends VBoxContainer
## The assembled expedition, with directly selectable miniature and roster slots.
signal inspect(slot: int)
signal spells
signal changed

var draft: WarbandDraft
var lineup: WarbandLineup
var _split: BoxContainer
var _stage: VBoxContainer
var _brief: VBoxContainer
var _slots: HFlowContainer
var _fill: Button


func setup(value: WarbandDraft) -> void:
	draft=value
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	_split=BoxContainer.new()
	_split.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_split.add_theme_constant_override("separation",10)
	add_child(_split)
	_stage=WorkshopUI.column(_split)
	_stage.size_flags_stretch_ratio=2.7
	lineup=WarbandLineup.new()
	lineup.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	lineup.size_flags_vertical=Control.SIZE_EXPAND_FILL
	lineup.custom_minimum_size=Vector2(0,230)
	_stage.add_child(lineup)
	lineup.selected.connect(func(slot: int) -> void: inspect.emit(slot))
	var tip := WorkshopUI.label(_stage,"Tap a miniature or a roster slot to inspect it.",18,WorkshopUI.MUTED)
	tip.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_brief=WorkshopUI.scroll(_split)
	_brief.get_parent().size_flags_stretch_ratio=1.0
	_slots=HFlowContainer.new()
	_slots.add_theme_constant_override("h_separation",6)
	_slots.add_theme_constant_override("v_separation",6)
	add_child(_slots)


func reflow(narrow: bool) -> void:
	_split.vertical=narrow
	_stage.size_flags_stretch_ratio=1.5 if narrow else 2.7
	lineup.custom_minimum_size.y=230 if narrow else 170


func refresh() -> void:
	lineup.set_draft(draft)
	WorkshopUI.clear(_brief)
	WorkshopUI.label(_brief,draft.wizard_name,32,WorkshopUI.GOLD)
	WorkshopUI.label(_brief,draft.school.capitalize()+" · "+WarbandAdvice.SCHOOLS.get(draft.school,""),22)
	WorkshopUI.button(_brief,"Customize wizard ›",func() -> void: inspect.emit(0))
	WorkshopUI.button(_brief,"Edit spellbook · %d/8 ›"%draft.spells.size(),func() -> void: spells.emit())
	WorkshopUI.button(_brief,"Apprentice equipped ›" if draft.apprentice else "Hire apprentice · 100 gc ›",func() -> void: inspect.emit(1))
	var hire := WorkshopUI.button(_brief,"Browse recruits ›",func() -> void: inspect.emit(draft.soldiers.size()+2),true)
	hire.disabled=draft.soldiers.size()>=WarbandDraft.MAX_SOLDIERS
	_fill=WorkshopUI.button(_brief,"Fill with free thugs",_fill_free)
	_fill.disabled=not draft.can_hire("thug")
	WorkshopUI.label(_brief,"Free recruits cost no gold. Unspent gold stays with your starting warband.",18,WorkshopUI.MUTED)
	WorkshopUI.clear(_slots)
	for i in 10:
		var title := "Wizard" if i==0 else ("Apprentice" if i==1 and draft.apprentice else ("+ Apprentice" if i==1 else ("+ Soldier" if i-2>=draft.soldiers.size() else draft.db.get_def(draft.soldiers[i-2]).name)))
		var b := WorkshopUI.button(_slots,title,inspect.emit.bind(i))
		b.custom_minimum_size=Vector2(108,58)
		b.add_theme_font_size_override("font_size",23)
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL


func _fill_free() -> void:
	while draft.can_hire("thug"):
		if not draft.hire("thug"):
			break
	changed.emit()
