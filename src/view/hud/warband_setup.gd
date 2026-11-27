class_name WarbandSetup
extends Window
## Full safe-area warband workshop. The draft remains the sole rules authority.
signal drafted(roster: Dictionary)

var draft: WarbandDraft
var _overview: WarbandOverview
var _inspector: WarbandInspector
var _spellbook: WarbandSpellbook
var _page: Control
var _heading: Label
var _summary: Label
var _status: Label
var _back: Button
var _save: Button
var _body: VBoxContainer
var _return_to_inspector := false


func _init() -> void:
	visible=false
	borderless=true
	unresizable=true
	transient=true
	exclusive=true


func setup(db: FigureDb,saved: Dictionary={}) -> void:
	draft=WarbandDraft.new(db)
	draft.choose_defaults()
	if not saved.is_empty():
		draft.restore_roster(saved)
	theme=BattleTheme.create()
	var root := PanelContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_stylebox_override("panel",BattleTheme.panel(Color("101d29"),Color("51636d"),0))
	add_child(root)
	var frame := VBoxContainer.new()
	frame.add_theme_constant_override("separation",8)
	root.add_child(frame)
	var header := HBoxContainer.new()
	frame.add_child(header)
	_back=WorkshopUI.button(header,"‹ Home",navigate_back)
	_heading=WorkshopUI.label(header,"YOUR EXPEDITION",30,WorkshopUI.GOLD)
	_heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_save=WorkshopUI.button(header,"Save warband",_confirm,true)
	_summary=WorkshopUI.label(frame,"",22,WorkshopUI.GOLD)
	_body=VBoxContainer.new()
	_body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	frame.add_child(_body)
	_status=WorkshopUI.label(frame,"",19,Color("edaa91"))
	_status.visible=false
	_overview=WarbandOverview.new()
	_body.add_child(_overview)
	_overview.setup(draft)
	_overview.inspect.connect(inspect)
	_overview.spells.connect(open_spells)
	_overview.changed.connect(_update)
	_inspector=WarbandInspector.new()
	_body.add_child(_inspector)
	_inspector.setup(draft)
	_inspector.changed.connect(_update_summary)
	_inspector.back.connect(show_overview)
	_inspector.spells.connect(open_spells)
	_spellbook=WarbandSpellbook.new()
	_body.add_child(_spellbook)
	_spellbook.setup(draft)
	_spellbook.changed.connect(_update_summary)
	close_requested.connect(navigate_back)
	get_parent().get_viewport().size_changed.connect(_fit)
	size_changed.connect(_reflow)
	show_overview()


func open(action: String) -> void:
	_save.text=action
	show_overview()
	ModalInput.register(self)
	var bounds := PhoneSafeArea.safe_rect(get_parent().get_viewport(),4)
	popup(Rect2i(Vector2i(bounds.position),Vector2i(bounds.size)))
	_reflow()


func _fit() -> void:
	if not visible:
		return
	var bounds := PhoneSafeArea.safe_rect(get_parent().get_viewport(),4)
	position=Vector2i(bounds.position)
	size=Vector2i(bounds.size)


func _reflow() -> void:
	if _overview==null:
		return
	var narrow := size.x<size.y
	_overview.reflow(narrow)
	_inspector.reflow(narrow)
	_spellbook.reflow(narrow)


func _show(page: Control,heading: String) -> void:
	for child in _body.get_children():
		child.visible=child==page
	_page=page
	_heading.text=heading
	_back.text="‹ Home" if page==_overview else "‹ Warband"
	_update_summary()


func show_overview() -> void:
	_show(_overview,"YOUR EXPEDITION")
	_overview.refresh()


func inspect(slot: int) -> void:
	_show(_inspector,"RECRUITMENT" if slot>=draft.soldiers.size()+2 else "CHARACTER DOSSIER")
	_inspector.inspect(slot)


func open_spells() -> void:
	_return_to_inspector=_page==_inspector
	_show(_spellbook,"SPELLBOOK")
	_spellbook.refresh()


func navigate_back() -> void:
	if _page==_spellbook and _return_to_inspector:
		_show(_inspector,"CHARACTER DOSSIER")
		_inspector.inspect(_inspector.slot)
	elif _page!=_overview:
		show_overview()
	else:
		hide()


func _update_summary() -> void:
	var problems := draft.errors()
	_summary.text="%d / %d gc remaining   •   %d/8 soldiers   •   %d/4 specialists"%[WarbandDraft.BUDGET-draft.cost(),WarbandDraft.BUDGET,draft.soldiers.size(),draft.specialists()]
	_status.text=" · ".join(problems)
	_status.visible=not problems.is_empty()
	_save.disabled=not problems.is_empty()


func _update() -> void:
	_update_summary()
	if _page==_overview:
		_overview.refresh()


func _confirm() -> void:
	if draft.errors().is_empty():
		drafted.emit(draft.as_warband())
		hide()
