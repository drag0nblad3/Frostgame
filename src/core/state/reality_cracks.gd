class_name RealityCracks
extends RefCounted
## Optional Red King rules, printed pp.9–18. One occurrence per battle.
const TWO := [20,18,16,14,12,8,4,1]
const MANY := [20,19,17,16,14,11,8,4]
const SCHOOLS := ["enchanter","necromancer","illusionist","witch","sigilist","elementalist","thaumaturge","soothsayer","chronomancer","summoner"]
const TITLES := ["Dislocation","Dark diagonal","Low gravity","Outward spin","Null wave","Implosion","Rainbow surge","Fold","Grey surge","Lightning front","Random exchange","Central escape","Portal","Convergence","Shifting ruins","Cloven hoof","Pocket sphere","Dimensional cross","Secret exchange","Enneahedron"]


static func allowed(s: GameState) -> bool:
	return s!=null and s.board.floor_layout.is_empty() and s.content_profile.rule("red_king_reality_cracks") and s.scenario_data.get("reality_enabled",false) and (not s.scenario_special.begins_with("red_king_") or s.scenario_special=="red_king_squatter")


static func id(s: GameState) -> int:
	return int(s.scenario_data.get("reality_current",0)) if s!=null else 0


static func threshold(turn: int,sides: int) -> int:
	var rows := TWO if sides<=2 else MANY
	return int(rows[clampi(turn-1,0,7)])


static func on_priority(c: GameController,rolls: Array) -> void:
	var s := c.state
	if not allowed(s):
		return
	if not s.scenario_data.get("reality_triggered",false):
		if not rolls.is_empty() and int(rolls.max())>threshold(s.turn,s.side_count()):
			apply(c,c.dice.d20())
		return
	var effect := id(s)
	if effect in [4,5,6,8,10] and c.dice.d20()>=17:
		_repeat(c,effect)
	elif effect in [7,9]:
		_school(c)
	elif effect==13:
		RealityCrackTerrain.spawn_portal(c)


static func on_end_turn(c: GameController) -> void:
	var effect := id(c.state)
	match effect:
		2:
			var roll := c.dice.d20()
			if roll>=17:
				clear(c)
			elif roll>=11:
				_diagonal(c,not c.state.scenario_data.get("reality_diagonal",false))
		3:
			if c.dice.d20()>=17:
				clear(c)
		11:
			_exchange(c,false)
		16:
			RealityCrackTerrain.hoof(c,false)
		17,20:
			if c.dice.d20()>=16:
				clear(c)
		18:
			if c.dice.d20()>=13:
				clear(c)
		19:
			_exchange(c,true)


static func apply(c: GameController,effect: int) -> bool:
	var s := c.state
	if effect<1 or effect>20 or s.scenario_data.get("reality_triggered",false):
		return false
	s.scenario_data["reality_triggered"]=true
	s.scenario_data["reality_current"]=effect
	s.scenario_data["reality_prior_boundaries"]=s.board.boundaries.duplicate(true)
	c.emit("reality_crack",{"number":effect,"name":TITLES[effect-1]})
	match effect:
		1:
			for f in s.figures.duplicate():
				if not f.in_play():
					continue
				for token in f.carried_treasures():
					c._loot._drop(f,f.pos,token)
				ForcedRelocation.relocate(c,f,f.pos+direction(c)*6.0)
			clear(c)
		2:
			_diagonal(c,c.dice.pick(2)==0)
		3:
			s.board.low_gravity=true
			s.board.invalidate_terrain()
		4,5,6,8,10:
			_repeat(c,effect)
		7,9:
			_school(c)
		13:
			RealityCrackTerrain.portal(c)
		14:
			_converge(c)
			clear(c)
		15:
			RealityCrackTerrain.shift_ruins(c)
			clear(c)
		16:
			RealityCrackTerrain.hoof(c,true)
		17,18,20:
			RealityCrackGeometry.apply(c,effect)
	return true


static func direction(c: GameController) -> Vector2:
	return Vector2.RIGHT.rotated(TAU*float(c.dice.pick(20))/20.0)


static func clear(c: GameController) -> void:
	var s := c.state
	s.scenario_data["reality_current"]=0
	var previous: Array[Dictionary]=[]
	previous.assign(s.scenario_data.get("reality_prior_boundaries",[]))
	s.board.set_boundaries(previous)
	s.board.low_gravity=false
	RealityCrackGeometry.clear(c)
	c.emit("boundary_changed",{})
	c.emit("reality_stable",{})


static func _diagonal(c: GameController,other: bool) -> void:
	var s := c.state
	s.scenario_data["reality_diagonal"]=other
	var size := s.board.size
	var lines: Array[Dictionary]=[]
	lines.assign(s.scenario_data.get("reality_prior_boundaries",[]))
	lines.append({"a":Vector2(size.x,0) if other else Vector2.ZERO,"b":Vector2(0,size.y) if other else size,"sight":true})
	s.board.set_boundaries(lines)
	c.emit("boundary_changed",{})


static func _repeat(c: GameController,effect: int) -> void:
	var s := c.state
	var center := s.board.size*0.5
	var axis := c.dice.pick(2) if effect in [8,10] else -1
	if effect==5:
		s.scenario_data["reality_null_turn"]=s.turn
		for f in s.figures.duplicate():
			if not f.in_play():
				continue
			ScenarioNull.cancel_spells(c,f)
			if f.in_play() and (f.def.traits.has("undead") or f.def.traits.has("construct")) and not StatRoll.succeeds(c.dice.d20(),f.effective_will()+f.roll_penalty(),12):
				f.spell_effects["reality_skip_turn"]=s.turn
		for p in s.board.pieces.duplicate():
			if p.kind.id.begins_with("spell_"):
				c._magic.terrain.remove(p)
		s.words.clear()
		s.fast_acts.clear()
		c.emit("reality_null",{})
		return
	for f in s.figures.duplicate():
		if not f.in_play():
			continue
		var delta: Vector2=center-f.pos
		if effect in [8,10]:
			delta=Vector2(delta.x,0) if axis==0 else Vector2(0,delta.y)
		if effect==10:
			if delta.length()<=4.0+Figure.BASE_RADIUS:
				environmental_attack(c,f,3,true)
			continue
		var origin: Vector2=f.pos
		for token in f.carried_treasures():
			if not StatRoll.succeeds(c.dice.d20(),f.effective_move()+MagicEquipment.bonus(f,"move_test")+f.roll_penalty(),18):
				var margin := Vector2.ONE*TreasureRules.TOKEN_RADIUS
				var target := (origin+direction(c)*6.0).clamp(margin,s.board.size-margin)
				c._loot._drop(f,target if s.board.can_stand(target,TreasureRules.TOKEN_RADIUS) else origin,token)
		if delta.is_zero_approx():
			continue
		var distance := 6.0 if effect==4 else minf(6.0,delta.length())
		c._magic.movement.force(f,delta.normalized()*(-1.0 if effect==4 else 1.0),distance)


static func environmental_attack(c: GameController,f: Figure,power: int,elemental: bool) -> void:
	var attack := c.dice.d20()+power
	var defence := c.dice.d20()+f.effective_fight()+f.roll_penalty()
	var damage := maxi(0,attack-f.effective_armour()-(CreatureEffects.elemental_resistance(f) if elemental else 0)) if attack>defence else 0
	if elemental:
		damage=RedKingElemental.reduce(c,f,damage)
	c.emit("reality_attack",{"id":f.id,"power":power,"amount":damage})
	c._hurt(f,damage,f,true)


static func _school(c: GameController) -> void:
	var school: String=SCHOOLS[c.dice.pick(SCHOOLS.size())]
	c.state.scenario_data["reality_school"]=school
	c.emit("reality_school",{"school":school,"bonus":5 if id(c.state)==7 else -5})


static func casting_modifier(s: GameState,spell: String) -> int:
	var effect := id(s)
	if effect==5 and int(s.scenario_data.get("reality_null_turn",-1))==s.turn:
		return -2
	if effect in [7,9] and s.spell_catalog.get(spell,{}).get("school","")==s.scenario_data.get("reality_school",""):
		return 5 if effect==7 else -5
	return 0


static func null_wave(f: Figure) -> bool:
	var s := RedKingVeil.of(f)
	return s!=null and id(s)==5 and int(s.scenario_data.get("reality_null_turn",-1))==s.turn


static func will_modifier(f: Figure) -> int:
	var effect := id(RedKingVeil.of(f))
	return 3 if effect==7 else (-2 if effect==9 else 0)


static func low_gravity(f: Figure) -> bool:
	return id(RedKingVeil.of(f))==3


static func activation(c: GameController,f: Figure) -> void:
	if int(f.spell_effects.get("reality_skip_turn",-1))==c.state.turn or bool(f.spell_effects.get("reality_skip_next",false)):
		f.spell_effects.erase("reality_skip_next")
		f.actions_left=0


static func blocks_exit(s: GameState) -> bool:
	return id(s) in [12,17,20]


static func can_exit_center(c: GameController) -> bool:
	var f := c.state.active()
	return id(c.state)==12 and f!=null and f.in_play() and f.side>=0 and f.actions_left>0 and not c.awaiting_reaction() and not c.state.group.in_progress() and not Contact.in_combat(c.state.figures,f) and not f.spell_effects.has("plane_walk") and f.pos.distance_to(c.state.board.size*0.5)<=Figure.BASE_RADIUS+0.01


static func exit_center(c: GameController) -> bool:
	if not can_exit_center(c):
		return false
	var f := c.state.active()
	for token in f.carried_treasures():
		c._loot.secure(c.state.treasure(token),f.side)
	f.exited=true
	f.actions_left=0
	c.emit("exit",{"id":f.id})
	return true


static func _exchange(c: GameController,secret: bool) -> void:
	var s := c.state
	var selected: Array[Figure]=[]
	var order := s.order.duplicate()
	if order.is_empty():
		for side in s.side_count():
			order.append(side)
	for side: int in order:
		var candidates: Array[Figure]=[]
		for f in s.side_figures(side):
			if not secret or (not f.def.traits.has("undead") and not f.def.traits.has("construct")):
				candidates.append(f)
		if candidates.size()>1:
			selected.append(candidates[c.dice.pick(candidates.size())])
	if selected.size()==1:
		if secret:
			clear(c)
			return
		for other in s.side_figures(selected[0].side):
			if other!=selected[0]:
				selected.append(other)
				break
	if selected.size()<2:
		return
	var locations: Array[Vector2]=[]
	for f in selected:
		locations.append(f.pos)
	if secret:
		for f in selected:
			for token in f.carried_treasures():
				if c.dice.d20()<13:
					var margin := Vector2.ONE*TreasureRules.TOKEN_RADIUS
					var target := (f.pos+direction(c)*2.0).clamp(margin,s.board.size-margin)
					c._loot._drop(f,target if s.board.can_stand(target,TreasureRules.TOKEN_RADIUS) else f.pos,token)
	for i in selected.size():
		var f := selected[i]
		var old := f.pos
		f.pos=locations[(i+1)%locations.size()]
		f.elevation=s.board.height_at(f.pos)
		f.disengaged.clear()
		c.emit("forced_relocation",{"id":f.id,"from":old,"at":f.pos,"height":f.elevation})


static func _converge(c: GameController) -> void:
	var s := c.state
	var center := s.board.size*0.5
	var moved := {}
	for i in 6:
		var end := center+direction(c)*s.board.size.length()
		var best: Figure=null
		var score := INF
		for f in s.figures:
			if not f.in_play() or moved.has(f.id) or f.pos.distance_to(Geometry2D.get_closest_point_to_segment(f.pos,center,end))>3.0:
				continue
			var d := f.pos.distance_squared_to(center)
			if d<score:
				best=f
				score=d
		if best!=null:
			moved[best.id]=true
			ForcedRelocation.relocate(c,best,center)
