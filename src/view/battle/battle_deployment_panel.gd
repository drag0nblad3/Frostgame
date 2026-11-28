class_name BattleDeploymentPanel
extends CanvasLayer
## Non-modal setup controls; board remains pannable and positions are chosen
## directly on the tactical surface. The controller owns all legal placement.

var battle: BattleScene
var setup: BattleDeployment
var _safe: PhoneSafeArea
var _panel: PanelContainer
var _heading: Label
var _hint: Label
var _edges: HFlowContainer
var _actions: HFlowContainer
var _units: OptionButton
var _confirm: Button
var _auto: Button
var _selected:=-1
var _points: Array[Dictionary]=[]


func open(bs: BattleScene) -> void:
	battle=bs
	setup=bs.controller.deployment
	layer=5
	_safe=PhoneSafeArea.new()
	_safe.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_safe.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_safe.theme=BattleTheme.create()
	add_child(_safe)
	_panel=PanelContainer.new()
	_safe.add_child(_panel)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",4)
	_panel.add_child(content)
	_heading=Label.new()
	_heading.add_theme_font_size_override("font_size",22)
	content.add_child(_heading)
	_hint=Label.new()
	_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size",18)
	content.add_child(_hint)
	_edges=HFlowContainer.new()
	content.add_child(_edges)
	_actions=HFlowContainer.new()
	content.add_child(_actions)
	_units=OptionButton.new()
	_units.custom_minimum_size=Vector2(160,48)
	_actions.add_child(_units)
	_units.item_selected.connect(func(i: int) -> void:
		_selected=_units.get_item_id(i)
		_refresh_points())
	_auto=_button("Auto deploy",_auto_finish)
	_actions.add_child(_auto)
	_confirm=_button("Confirm deployment",_finish)
	_actions.add_child(_confirm)
	_refresh()


func blocks(at: Vector2) -> bool:
	return is_instance_valid(_panel) and _panel.get_global_rect().has_point(at)


func _button(title: String,call: Callable) -> Button:
	var b:=Button.new()
	b.text=title
	b.custom_minimum_size.y=48
	b.pressed.connect(call)
	return b


func _refresh() -> void:
	for child in _edges.get_children():
		_edges.remove_child(child)
		child.queue_free()
	_sync_treasures()
	if setup.treasure_stage>0:
		_heading.text="Treasure setup · Place your "+("inner" if setup.treasure_stage==1 else "outer")+" treasure"
		_hint.text="Choose a highlighted legal position. The rival places one next. Starting edges are rolled only after treasure placement."
		if not setup.error.is_empty():
			_hint.text=setup.error
		_edges.hide()
		_units.hide()
		_confirm.hide()
		_auto.text="Auto place remaining treasures"
		_sync_figures()
		_refresh_points()
		return
	_auto.text="Auto deploy"
	var waiting:=not setup.zones.has(battle.player_side)
	_heading.text="Deployment · "+("Choose your starting position" if waiting else "Arrange your warband")
	var roll_text:=""
	if not setup.rolls.is_empty():
		roll_text="Roll-off: you %d · rival %d. "%[setup.rolls[battle.player_side],setup.rolls[1-battle.player_side]]
	_hint.text=roll_text+("Select a legal edge or corner." if waiting else "Choose a figure, then tap a highlighted legal position. Confirm when ready.")
	if not setup.error.is_empty():
		_hint.text=setup.error
	_edges.visible=waiting
	if waiting:
		for zone in setup.available():
			var chosen:=zone
			_edges.add_child(_button(DeploymentRules.label(setup.c.state,zone),func() -> void:
				setup.choose(chosen)
				_refresh()))
	_units.visible=not waiting
	_confirm.visible=not waiting
	_units.clear()
	if not waiting:
		for f in setup.c.state.side_figures(battle.player_side):
			_units.add_item(f.label(),f.id)
		if _units.item_count>0:
			var item:=_units.get_item_index(_selected)
			_units.select(maxi(0,item))
			_selected=_units.get_selected_id()
	_sync_figures()
	_refresh_points()


func _sync_figures() -> void:
	for f in setup.c.state.figures:
		if not battle.player.views.has(f.id):
			continue
		var v: FigureView=battle.player.views[f.id]
		v.position=TableSpace.to_world(f.pos,f.elevation)
		v.visible=f.in_play() and setup.visible(f)
		v.set_active(f.id==_selected and v.visible)


func _sync_treasures() -> void:
	for t in setup.c.state.treasures:
		var marker: MeshInstance3D=battle.player.treasure_views.get(t.id)
		if marker==null:
			continue
		marker.position=TableSpace.to_world(t.pos,TreasureRules.token_height(setup.c.state,t)+0.25)
		marker.visible=t.on_ground() and (setup.treasure_stage==0 or t.id<setup.treasure_stage) and not (setup.c.state.scenario_special=="complex_temple" and t.frozen)


func _refresh_points() -> void:
	if setup.treasure_stage>0:
		_points=setup.treasure_options()
	else:
		_points=setup.points(_selected)
	battle._markers.clear()
	var world:=PackedVector3Array()
	for p in _points:
		var at: Vector2=p["at"]
		world.append(TableSpace.to_world(at,float(p.get("height",p.get("world",Vector3.ZERO).y))))
	battle._markers.show_world_points(world,Color("7cd9ae"),0.16)
	if setup.treasure_stage>0:
		return
	var f:=setup.c.state.figure(_selected)
	if f!=null and setup.visible(f):
		battle._markers.show_world_points(PackedVector3Array([TableSpace.to_world(f.pos,f.elevation)]),Color("f4d58c"),0.64,true)
	_sync_figures()


func tap(screen: Vector2) -> void:
	if blocks(screen):
		return
	var best: Dictionary={}
	var distance:=28.0
	for p in _points:
		var at: Vector2=p["at"]
		var world:=TableSpace.to_world(at,float(p.get("height",p.get("world",Vector3.ZERO).y)))
		if battle._rig.camera.is_position_behind(world):
			continue
		var d:=screen.distance_to(battle._rig.camera.unproject_position(world))
		if d<distance:
			best=p
			distance=d
	if not best.is_empty() and setup.treasure_stage>0:
		setup.place_treasure(best)
		_refresh()
		return
	if not best.is_empty() and setup.move(_selected,best):
		_refresh_points()


func _auto_finish() -> void:
	if setup.treasure_stage>0:
		setup.finish_treasure_setup()
		_refresh()
		return
	if not setup.zones.has(battle.player_side) and not setup.auto_choose():
		_refresh()
		return
	_finish()


func _finish() -> void:
	if not setup.confirm():
		_refresh()
		return
	_sync_figures()
	battle._deployment_complete()
