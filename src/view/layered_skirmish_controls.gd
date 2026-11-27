class_name LayeredSkirmishControls
extends PanelContainer
var scene: Node3D
var c: GameController
var destinations := {}
var mode := "move"
var leap_target := -1
var bridge_start: Variant = null
var hint: Label
var log_line: Label
var _buttons := {}
var _cast_row: HBoxContainer
var _empower: SpinBox
var _resolve_button: Button
var _donor: OptionButton
var _stolen: SpinBox
var _reaction_key := ""
const PLAN_MODES := ["move","run_for_it","run_talisman","cape_move","jump","exit"]
var planned: Variant=null
var planned_actor := -1
var planned_target := -1
var _reach: LayeredReach
var _jump_plans := {}
var _preview_tween: Tween
var _summary: Label
var _result: Label
var _row: GridContainer
var _scroll: ScrollContainer


func setup(host: Node3D) -> void:
	scene=host
	c=scene.controller
	var col := VBoxContainer.new()
	add_child(col)
	log_line=Label.new()
	log_line.text="Battle • %d figures, %d treasures" % [c.state.figures.size(),c.state.treasures.size()]
	log_line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	col.add_child(log_line)
	log_line.add_theme_font_size_override("font_size",19)
	_result=Label.new()
	_result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_result.modulate=Color("e5c58a")
	_result.add_theme_font_size_override("font_size",20)
	_result.hide()
	col.add_child(_result)
	_summary=Label.new()
	_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_summary.modulate=Color("e5c58a")
	_summary.add_theme_font_size_override("font_size",22)
	col.add_child(_summary)
	hint=Label.new()
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	col.add_child(hint)
	_hint_style()
	_scroll=ScrollContainer.new()
	_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(_scroll)
	_row=GridContainer.new()
	_row.columns=2
	_row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_row.add_theme_constant_override("h_separation",10)
	_row.add_theme_constant_override("v_separation",10)
	_scroll.add_child(_row)
	for entry: Array in [["plan_confirm","Confirm move"],["plan_undo","Undo move"],["attack_confirm","Confirm attack"],["attack_cancel","Cancel attack"],["group","Group activation"],["finish_early","Finish phase"],["move","Move"],["death_mask","Toggle Death Mask"],["run_for_it","Run 3″"],["run_talisman","Run 6″ (Talisman)"],["cape_move","Escape (Dazzling Cape)"],["jump","Jump"],["fight","Fight"],["gutter_skip","Skip free flail attack"],["shoot","Shoot"],["ammo_shot","Enchanted shot"],["bottle_imp","Release Bottle Imp"],["resist_fate","Reroll resistance"],["resist_amulet","Use resistance amulet"],["cast_fate","Reroll casting"],["cast_scroll","Use scroll"],["fate_yes","Reroll combat"],["fate_no","Keep combat roll"],["cast","Cast spell"],["collect","Collect"],["exit","Extract"],["teleport","Teleport"],["leap","Leap"],["bridge","Bridge"],["cancel_bridge","Dismiss bridge"],["reload","Reload"],["push_self","Withdraw 1″"],["push_self_5","Back ½″"],["push_self_15","Back 1½″"],["push_self_20","Back 2″"],["push_self_25","Back 2½″"],["push_self_30","Back 3″"],["push_enemy","Push enemy"],["stay","Stay"],["end","End activation"],["rival","Rival activation"]]:
		var b := Button.new()
		b.text=entry[1]
		b.custom_minimum_size=Vector2(0,72)
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size",22)
		b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		b.tooltip_text=b.text
		ActionArt.apply(b,str(entry[0]),{})
		if entry[0] in ["plan_confirm","attack_confirm"]:
			b.add_theme_stylebox_override("normal",BattleTheme.panel(Color("305664"),Color("e5c58a")))
		b.pressed.connect(command.bind(str(entry[0])))
		_row.add_child(b)
		_buttons[entry[0]]=b
	_cast_row=HBoxContainer.new()
	col.add_child(_cast_row)
	_empower=SpinBox.new()
	_empower.min_value=0
	_empower.step=1
	_empower.prefix="Empower "
	_cast_row.add_child(_empower)
	_resolve_button=Button.new()
	_resolve_button.text="Resolve cast"
	_resolve_button.custom_minimum_size.y=64
	_resolve_button.pressed.connect(_resolve)
	_cast_row.add_child(_resolve_button)
	_donor=OptionButton.new()
	_donor.custom_minimum_size.y=64
	col.add_child(_donor)
	_stolen=SpinBox.new()
	_stolen.prefix="Steal +"
	_stolen.step=1
	col.add_child(_stolen)
	_donor.item_selected.connect(func(i: int) -> void:
		var cast := c.state.pending_resistance.is_empty()
		var p := c.state.pending_cast if cast else c.state.pending_resistance
		if p.is_empty():
			return
		p["vampire_donor"]=int(_donor.get_item_metadata(i))
		p["vampire_amount"]=0
		_refresh_donor(p,cast))
	_stolen.value_changed.connect(func(value: float) -> void:
		var cast := c.state.pending_resistance.is_empty()
		var p := c.state.pending_cast if cast else c.state.pending_resistance
		if p.is_empty():
			return
		p["vampire_amount"]=int(value)
		if cast:
			_empower.max_value=c.cast_max_empowerment())
	scene.player.line_logged.connect(func(line: String) -> void:log_line.text=line)
	scene.player.notice.connect(func(line: String) -> void:log_line.text=line)
	scene.player.roll_resolved.connect(func(line: String) -> void:
		_result.text=line
		_result.show())


func _hint_style() -> void:
	hint.add_theme_font_size_override("font_size",22)


func fit_dock(wide: bool,bounds: Vector2) -> void:
	custom_minimum_size.x=clampf(bounds.x*0.29,310.0,420.0) if wide else 0.0
	_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL if wide else Control.SIZE_FILL
	_scroll.custom_minimum_size.y=0.0 if wide else minf(170.0,bounds.y*0.28)
	_row.columns=1 if wide else maxi(2,mini(4,floori(bounds.x/190.0)))


func human() -> bool:
	return not c.state.over and c.state.current_side()==0


func marker_color() -> Color:
	return Color(0.75,0.46,1.0) if mode in ["teleport","leap_land","bridge","bridge_end"] else (Color(1.0,0.77,0.30) if mode=="exit" else Color(0.30,0.96,0.77))


func refresh() -> void:
	destinations.clear()
	var s := c.state
	var f := s.active()
	var idle: bool = scene.player.idle()
	_summary.text=BattleHud.active_summary(f) if idle else ""
	_summary.visible=not _summary.text.is_empty()
	if planned!=null and (f==null or f.id!=planned_actor or not idle):
		clear_plan()
	for key: String in _buttons:
		_buttons[key].visible=false
	_cast_row.hide()
	_donor.hide()
	_stolen.hide()
	if s.over:
		hint.text="Battle complete: "+("Draw" if s.winner<0 else s.side_names[s.winner]+" wins")
		return
	if not idle:
		hint.text="Resolving action…"
		return
	if not s.pending_combat.is_empty():
		_show("fate_yes",true)
		_show("fate_no",true)
		hint.text="Fate Stone: choose whether to reroll the combat die."
		return
	if not s.pending_resistance.is_empty() or (human() and not s.pending_cast.is_empty()):
		var cast := s.pending_resistance.is_empty()
		var p := s.pending_cast if cast else s.pending_resistance
		var caster := s.figure(p["caster"] if cast else p["id"])
		_cast_row.show()
		var key := "%s:%s:%s:%s"%[s.turn,p.get("caster",p.get("id",-1)),p.get("raw",0),cast]
		if key!=_reaction_key:
			_empower.value=0
			_reaction_key=key
		_empower.max_value=c.cast_max_empowerment() if cast else int(p["max"])
		_resolve_button.text="Resolve cast" if cast else "Resolve resistance"
		hint.text="%s: roll %d, target %d. Choose empowerment."%[caster.label(),p.get("total",int(p.get("raw",0))+int(p.get("mod",0))),p["tn"]]
		if cast:
			if not p.get("scroll",false) and ActiveGear.ready(caster,"gear_fate_stone"):
				_show("cast_fate",true)
			if c._magic.can_insure():
				_show("cast_scroll",true)
		else:
			if ActiveGear.ready(caster,"gear_fate_stone"):
				_show("resist_fate",true)
			if int(p["raw"])!=1 and ActiveGear.ready(caster,"gear_amulet_resistance"):
				_show("resist_amulet",true)
		_refresh_donor(p,cast)
		return
	_reaction_key=""
	if s.push_winner>=0:
		var winner := s.figure(s.push_winner)
		if winner!=null and winner.side==0:
			_show("push_self",c.can_push(true))
			for distance in [0.5,1.5,2.0,2.5,3.0]:
				if c.can_push(true,distance):
					_show("push_self_"+str(int(distance*10)),true)
			_show("push_enemy",c.can_push(false))
			_show("stay",true)
			hint.text="Choose the outcome of melee contact."
			return
		# Rival decisions after human attacks must resolve before further actions.
		if not c.resolve_push(false):
			c.stay_in_combat()
		scene.call_deferred("refresh")
		return
	if s.pending_gutter>=0 and human():
		mode="gutter_fight"
		_show("gutter_skip",true)
		hint.text="Gutter Flail: tap an enemy for a free attack or skip."
		return
	if not human():
		_show("rival",true)
		hint.text="Advance the rival warband one activation."
		return
	if f==null:
		_show("group",c.can_begin_group())
		_buttons["group"].visible=c.can_begin_group()
		_show("finish_early",c.can_finish_early_phase())
		_buttons["finish_early"].visible=c.can_finish_early_phase()
		if s.group.in_progress():
			hint.text=("Group movement pass" if s.group.movement_pass() else "Group second-action pass")+" • Tap a remaining member."
		else:
			hint.text="Tap an eligible friendly figure to activate. Select a floor to reveal hidden figures."
		return
	hint.text="%s • %s • %.1f″ elevation • %d actions • %s" % [f.label(),f.surface_id.capitalize(),f.elevation,f.actions_left,mode.capitalize()]
	if s.group.in_progress():
		hint.text+=" • "+("GROUP MOVE" if s.group.movement_pass() else "GROUP SECOND")
	_show("end",c.can_end_activation())
	_show("move",c.can_move())
	if DeathMask.can_toggle(c):
		_show("death_mask",true)
	if RunForIt.ready(c):
		_show("run_for_it",LayeredMovement.eligible(c))
	if RunForIt.ready(c,true):
		_show("run_talisman",LayeredMovement.eligible(c))
	if GearActions.cape_ready(c):
		_show("cape_move",LayeredMovement.eligible(c,true))
	var jumps := LayeredJump.plans(c)
	_show("jump",not jumps.is_empty())
	_show("reload",c.can_reload())
	var exits: Array[Vector3i] = []
	if f.treasure_id>=0:
		exits=c.floor_exit_nodes()
	_show("exit",not exits.is_empty())
	var loot := false
	for token in s.treasures:
		loot=loot or c.can_pick_up(token.id)
	_show("collect",loot)
	var fight := false
	var shoot := false
	for t in s.figures:
		fight=fight or c.can_fight(t.id)
		shoot=shoot or c.can_shoot(t.id)
	_show("fight",fight)
	_show("shoot",shoot)
	var ammo := false
	for t in s.figures:
		ammo=ammo or c.can_shoot(t.id,false,true)
	if ammo:
		_show("ammo_shot",true)
	var bottle := GearActions.bottle_floor_points(c)
	if not bottle.is_empty():
		_show("bottle_imp",true)
		if mode=="bottle_imp":
			destinations=bottle
			hint.text="Choose a legal nearby floor position for the imp."
	_show("cast",not LayeredFigureSpells.options(c).is_empty())
	if ScenarioNull.muted(f):
		hint.text+=" • NULL FIELD"
	var teleport := not ScenarioNull.muted(f) and CasterLoadout.is_caster(f.def.role) and c.can_act() and c._magic.available_spell(f,"teleport") and not Contact.in_combat(s.figures,f) and not s.group.in_progress()
	_show("teleport",teleport)
	var leap := false
	for t in s.figures:
		leap=leap or LayeredLeap.eligible(c,t)
	_show("leap",leap)
	_show("bridge",LayeredBridge.eligible(c))
	_show("cancel_bridge",not LayeredBridge.owned(s,f.id).is_empty())
	if mode=="move" and c.can_move():
		_reach=c.layered_reach()
		for n: Vector3i in _reach.cost:
			if n!=_reach.start:
				destinations[n]=true
	elif mode in ["run_for_it","run_talisman"]:
		_reach=LayeredMovement.reach(c,false,true,mode=="run_talisman")
		for n: Vector3i in _reach.cost:
			if n!=_reach.start:
				destinations[n]=true
		hint.text="Choose a run destination; ends activation."
	elif mode=="cape_move" and LayeredMovement.eligible(c,true):
		_reach=LayeredMovement.reach(c,true)
		for n: Vector3i in _reach.cost:
			if n!=_reach.start:
				destinations[n]=true
		hint.text="Choose a legal escape destination."
	elif mode=="jump":
		_jump_plans=jumps
		destinations=jumps
	elif mode=="exit":
		_reach=c.layered_reach()
		for n in exits:
			destinations[n]=true
	elif mode=="teleport" and teleport:
		_teleport_points(f)
	elif mode in ["bridge","bridge_end"]:
		var layout: FloorLayout = scene.layout
		var index: int = scene.floor_choice.selected
		if index>=layout.surfaces.size():
			index=layout.index_of(f.surface_id)
		destinations=LayeredBridgePicker.points(c,layout,index,bridge_start if mode=="bridge_end" else null)
		hint.text="Choose the first bridge endpoint." if mode=="bridge" else "Choose another floor and the second endpoint."
		if ActiveGear.ready(f,TerrainMagic.EXTENDED):
			hint.text+=" A 9″ span uses the Extended Scroll on success."
	elif mode=="leap":
		hint.text="Choose a friendly figure visible to the caster."
	elif mode=="leap_land":
		var t := s.figure(leap_target)
		if LayeredLeap.eligible(c,t):
			hint.text="Choose a floor, then a legal Leap landing for "+t.label()+"."
			_leap_points(t)
	if planned!=null:
		if destinations.has(planned):
			_show_plan()
		else:
			clear_plan()
	elif planned_target>=0:
		_show_attack()
	elif mode in PLAN_MODES:
		hint.text+="\nTap or drag to plan, then confirm. Change floors to reach other levels."


func _teleport_points(f: Figure) -> void:
	var layout: FloorLayout = scene.layout
	var index: int = scene.floor_choice.selected
	if index>=layout.surfaces.size():
		index=layout.index_of(f.surface_id)
	var surface := layout.surfaces[index]
	var grid := LayeredGrid.new(layout,f,c.state.figures)
	for x in range(ceili(surface.rect.position.x/MoveGrid.STEP),floori(surface.rect.end.x/MoveGrid.STEP)+1):
		for y in range(ceili(surface.rect.position.y/MoveGrid.STEP),floori(surface.rect.end.y/MoveGrid.STEP)+1):
			var n := Vector3i(x,y,index)
			if LayeredMagic.can_teleport_with(c,n,layout,grid):
				destinations[n]=true


func _leap_points(t: Figure) -> void:
	var layout: FloorLayout = scene.layout
	var index: int = scene.floor_choice.selected
	if index>=layout.surfaces.size():
		index=layout.index_of(t.surface_id)
	if index<0:
		return
	var surface := layout.surfaces[index]
	var grid := LayeredGrid.new(layout,t,c.state.figures)
	for x in range(ceili(surface.rect.position.x/MoveGrid.STEP),floori(surface.rect.end.x/MoveGrid.STEP)+1):
		for y in range(ceili(surface.rect.position.y/MoveGrid.STEP),floori(surface.rect.end.y/MoveGrid.STEP)+1):
			var n := Vector3i(x,y,index)
			if not LayeredLeap.path(c,t,n,layout,grid).is_empty():
				destinations[n]=true


func _show(key: String,enabled: bool) -> void:
	_buttons[key].visible=true
	_buttons[key].disabled=not enabled


func _resolve() -> void:
	if not c.state.pending_resistance.is_empty():
		c._magic.resistance.answer(int(_empower.value))
	else:
		c.finish_cast(int(_empower.value))
	mode="move"
	scene.refresh()


func command(key: String) -> void:
	if not scene.player.idle() or not _buttons.has(key) or _buttons[key].disabled or not _buttons[key].visible:
		return
	match key:
		"plan_confirm":
			if planned!=null:
				var n: Vector3i=planned
				clear_plan()
				_commit_destination(n)
		"plan_undo": clear_plan()
		"attack_cancel":
			planned_target=-1
			scene.clear_plan_art()
		"attack_confirm":
			var target:=planned_target
			planned_target=-1
			scene.clear_plan_art()
			if mode=="fight":
				c.fight(target)
			else:
				c.shoot(target,false,mode=="ammo_shot")
		"cast_fate": c._magic.reroll_fate()
		"cast_scroll": c._magic.insure()
		"resist_fate": c._magic.resistance.reroll_fate()
		"resist_amulet": c._magic.resistance.use_amulet()
		"fate_yes","fate_no": c.answer_fate_combat(key=="fate_yes")
		"group":
			LayeredGroupPicker.choose(self,c,scene.refresh)
		"finish_early":
			c.finish_early_phase()
		"cast":
			LayeredSpellPicker.choose(self,c,scene.refresh)
		"move","run_for_it","run_talisman","cape_move","jump","fight","shoot","ammo_shot","bottle_imp","exit","teleport","leap","bridge":
			mode=key
			bridge_start=null
		"death_mask":
			DeathMask.toggle(c)
			mode="move"
		"cancel_bridge":
			c.cancel_floor_bridge()
			mode="move"
		"collect":
			for token in c.state.treasures:
				if c.can_pick_up(token.id):
					c.pick_up(token.id)
					break
			mode="move"
		"reload":
			c.reload()
		"push_self","push_enemy":
			c.resolve_push(key=="push_self")
		"push_self_5","push_self_15","push_self_20","push_self_25","push_self_30":
			c.resolve_push(true,float(key.trim_prefix("push_self_"))/10.0)
		"gutter_skip":
			GearActions.gutter_skip(c)
			mode="move"
		"stay":
			c.stay_in_combat()
		"end":
			c.end_activation()
			mode="move"
		"rival":
			Bot.play_activation(c)
			mode="move"
	scene.refresh()


func tap_figure(screen: Vector2) -> bool:
	if not human() or not scene.player.idle() or c.awaiting_reaction() or not c.state.pending_cast.is_empty() or c.state.push_winner>=0:
		return false
	var f := c.state.active()
	if f!=null and mode not in ["fight","shoot","ammo_shot","leap","gutter_fight"]:
		return false
	var chosen: Figure = null
	var distance := 38.0
	for t in c.state.figures:
		var v: FigureView = scene.player.views[t.id]
		if not t.in_play() or not v.visible:
			continue
		if f==null and not c.activatable().has(t):
			continue
		if f!=null:
			if mode=="leap" and not LayeredLeap.eligible(c,t):
				continue
			if mode=="gutter_fight" and not GearActions.gutter_targets(c).has(t):
				continue
			if mode=="fight" and not c.can_fight(t.id):
				continue
			if mode in ["shoot","ammo_shot"] and not c.can_shoot(t.id,false,mode=="ammo_shot"):
				continue
		var at := v.position+Vector3.UP*0.8
		if scene.rig.camera.is_position_behind(at):
			continue
		var d: float = scene.rig.camera.unproject_position(at).distance_to(screen)
		if d<distance:
			chosen=t
			distance=d
	if chosen==null:
		return false
	if f==null:
		c.activate(chosen.id)
		mode="move"
		scene.floor_choice.select(scene.layout.index_of(chosen.surface_id))
	elif mode=="gutter_fight":
		GearActions.gutter_fight(c,chosen.id)
		mode="move"
	elif mode=="fight":
		planned_target=chosen.id
		_show_attack()
	elif mode=="leap":
		leap_target=chosen.id
		mode="leap_land"
		scene.floor_choice.select(scene.layout.index_of(chosen.surface_id))
	else:
		planned_target=chosen.id
		_show_attack()
	return true


func choose_destination(n: Vector3i) -> void:
	if not destinations.has(n) or not human() or not scene.player.idle():
		return
	if mode in PLAN_MODES:
		plan_destination(n)
		return
	_commit_destination(n)


func _commit_destination(n: Vector3i) -> void:
	match mode:
		"bottle_imp":
			GearActions.bottle_on_floor(c,n)
			mode="move"
		"move": c.move_on_floor(n)
		"run_for_it","run_talisman":
			LayeredMovement.move(c,n,false,true,mode=="run_talisman")
			mode="move"
		"cape_move":
			LayeredMovement.move(c,n,true)
			mode="move"
		"jump":
			c.jump_on_floor(n)
			mode="move"
		"exit":
			if c.exit_on_floor(n):
				c.end_activation()
			mode="move"
		"teleport": c.teleport_on_floor(n)
		"leap_land": c.leap_on_floor(leap_target,n)
		"bridge":
			bridge_start=n
			mode="bridge_end"
		"bridge_end":
			if c.bridge_on_floors(bridge_start,n):
				bridge_start=null
				mode="move"


func _refresh_donor(p: Dictionary,cast: bool) -> void:
	_donor.clear()
	_donor.add_item("No Vampire Staff sacrifice")
	_donor.set_item_metadata(0,-1)
	var f := c.state.figure(p["caster"] if cast else p["id"])
	var selected := 0
	for donor in VampireStaff.donors(c.state,f):
		_donor.add_item("%s #%d · %d HP (survivor deserts)"%[donor.label(),donor.id,donor.health])
		_donor.set_item_metadata(_donor.item_count-1,donor.id)
		if donor.id==int(p.get("vampire_donor",-1)):
			selected=_donor.item_count-1
	_donor.select(selected)
	_donor.visible=_donor.item_count>1 and not p.get("scroll",false)
	_stolen.max_value=VampireStaff.cap(c,p,cast)
	_stolen.set_value_no_signal(VampireStaff.amount(c,p,cast))
	_stolen.visible=_donor.visible and selected>0
	if cast:
		_empower.max_value=c.cast_max_empowerment()


func clear_plan() -> void:
	if _preview_tween!=null and _preview_tween.is_valid():
		_preview_tween.kill()
	if planned_actor>=0 and scene.player.views.has(planned_actor):
		var f := c.state.figure(planned_actor)
		var v: FigureView=scene.player.views[planned_actor]
		if f!=null:
			v.position=TableSpace.to_world(f.pos,f.elevation)
	planned=null
	planned_actor=-1
	scene.clear_plan_art()


func plan_destination(n: Vector3i) -> void:
	var f := c.state.active()
	if f==null or not destinations.has(n) or mode not in PLAN_MODES:
		return
	if planned==n:
		return
	planned=n
	planned_actor=f.id
	var v: FigureView=scene.player.views[f.id]
	var point: Vector3=scene.layout.world(n)
	if _preview_tween!=null and _preview_tween.is_valid():
		_preview_tween.kill()
	if v.position.distance_to(point)<=1.25:
		_preview_tween=create_tween()
		_preview_tween.tween_property(v,"position",point,0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		v.position=point
	v.visible=true
	var points := PackedVector3Array()
	if mode=="jump":
		points=_jump_plans[n]["path"]
	elif _reach!=null:
		for step in _reach.path_to(n):
			points.append(scene.layout.world(step))
	scene.show_plan_art(points,scene.layout.world(n))
	_show_plan()


func _show_plan() -> void:
	for key in _buttons:
		_buttons[key].visible=false
	_show("plan_confirm",true)
	_show("plan_undo",true)
	_buttons["plan_confirm"].text="Confirm jump" if mode=="jump" else ("Confirm retreat" if mode=="exit" else "Confirm move")
	var n: Vector3i=planned
	var f := c.state.active()
	var cost: float=float(_jump_plans[n]["cost"]) if mode=="jump" else float(_reach.cost.get(n,0.0))
	var budget := 3.0 if mode=="run_for_it" else (6.0 if mode=="run_talisman" else MoveRules.allowance(f))
	hint.text="PREVIEW · %s · %.1f″ elevation\n%.1f″ / %.1f″ movement · %.1f″ remaining\nConfirm or undo. No action spent yet."%[scene.layout.surface_id(n).capitalize(),scene.layout.height(n),cost,budget,maxf(0.0,budget-cost)]
	if mode=="jump":
		hint.text+="\nLanding may cause falling damage."
	elif mode in ["run_for_it","run_talisman"]:
		hint.text+="\nRunning ends activation."


func _show_attack() -> void:
	var target:=c.state.figure(planned_target)
	var f:=c.state.active()
	if target==null or f==null:
		planned_target=-1
		return
	for key in _buttons:
		_buttons[key].visible=false
	_show("attack_confirm",true)
	_show("attack_cancel",true)
	hint.text="%s · HP %d/%d · Fight %+d · Armour %d\n%s · Confirm to roll or select another target."%[target.label(),target.health,target.def.health,target.effective_fight(),target.effective_armour(),("%s · %.1f″ / %.0f″"%[f.ranged.name,Shooting.distance(f,target),f.ranged.range_in]) if mode!="fight" else f.melee.name]
	scene.show_plan_art(PackedVector3Array(),TableSpace.to_world(target.pos,target.elevation))
