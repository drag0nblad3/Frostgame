class_name DeploymentScreen
extends ExpeditionScreen
## Safe-area deployment with an edge roll and tap-to-place roster.
signal confirmed(plan: DeploymentPlan)
signal abandoned
var plan: DeploymentPlan
var _map: DeploymentMap
var _edges: OptionButton
var _units: ItemList
var _split: BoxContainer
var _hint: Label
var _ids: Array[int]=[]


func _ready() -> void:
	build("DEPLOY WARBAND","Begin battle",_confirm)
	_edges=OptionButton.new()
	_edges.custom_minimum_size.y=56
	body.add_child(_edges)
	_edges.item_selected.connect(_choose)
	_split=BoxContainer.new()
	_split.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_child(_split)
	_map=DeploymentMap.new()
	_map.size_flags_stretch_ratio=2.0
	_split.add_child(_map)
	_map.placed.connect(_place)
	_units=ItemList.new()
	_units.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_units.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_units.add_theme_constant_override("v_separation",16)
	_units.add_theme_font_size_override("font_size",22)
	_split.add_child(_units)
	_units.item_selected.connect(func(i: int) -> void:
		_map.selected=_ids[i]
		_map.queue_redraw())
	var row:=HBoxContainer.new()
	body.add_child(row)
	WorkshopUI.button(row,"Auto deploy",_auto)
	_hint=WorkshopUI.label(row,"",20,WorkshopUI.MUTED)
	_hint.size_flags_horizontal=Control.SIZE_EXPAND_FILL


func open(p: DeploymentPlan) -> void:
	plan=p
	_map.plan=p
	_edges.clear()
	for e in DeploymentRules.choices(p.scenario):
		var label_text: String=DeploymentRules.EDGE_NAMES[e]
		if DeploymentRules.mode(p.scenario).begins_with("corner"):
			label_text="Left starting corner" if e==0 else "Right starting corner"
		_edges.add_item(label_text,e)
	for i in _edges.item_count:
		if _edges.get_item_id(i)==p.edge[p.human]:
			_edges.select(i)
	_edges.disabled=not p.can_choose()
	subtitle.text="Deployment roll: %s · %s chooses first."%[str(p.rolls),p.state.side_names[p.winner]] if not p.rolls.is_empty() else "Scenario-specific starting area."
	_units.clear()
	_ids.clear()
	for f in p.state.side_figures(p.human):
		_ids.append(f.id)
		_units.add_item("%d · %s"%[f.id,f.label()])
	if not _ids.is_empty():
		_units.select(0)
		_map.selected=_ids[0]
	_update()
	show_screen()


func _choose(i: int) -> void:
	if plan.can_choose():
		plan.choose(_edges.get_item_id(i))
	_update()


func _place(at: Vector2) -> void:
	if _map.selected>=0 and not plan.move(_map.selected,at):
		_hint.text="Choose a free point in the highlighted zone."
		return
	_update()


func _auto() -> void:
	plan.auto_human()
	_update()


func _update() -> void:
	action.disabled=not plan.complete()
	_hint.text="Select a unit, then tap a free highlighted point. Auto deploy is ready." if plan.complete() else plan.error
	_map.queue_redraw()


func _confirm() -> void:
	if not plan.complete():
		return
	hide()
	confirmed.emit(plan)


func navigate_back() -> void:
	hide()
	abandoned.emit()


func _reflow() -> void:
	if _split!=null:
		_split.vertical=size.x<size.y
