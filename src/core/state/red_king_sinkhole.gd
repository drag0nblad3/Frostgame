class_name RedKingSinkhole
extends RefCounted
## Red King scenario eight. The orb is independent of its rendered mesh.
const ID := "red_king_sinkhole"
const RADIUS := 1.5


static func active(s: GameState) -> bool:
	return s!=null and s.scenario_special==ID


static func center(s: GameState) -> Vector2:
	return s.board.size*0.5


static func distance(s: GameState,at: Vector2,radius: float=Figure.BASE_RADIUS) -> float:
	return maxf(0.0,at.distance_to(center(s))-RADIUS-radius)


static func touches(s: GameState,at: Vector2) -> bool:
	return active(s) and distance(s,at)<=0.001


static func casting_modifier(s: GameState,f: Figure) -> int:
	if not active(s):
		return 0
	var d := distance(s,f.pos)
	return -4 if d<=1.0 else (-2 if d<=8.0 else -1)


static func contact(c: GameController,f: Figure,forced: bool=false) -> void:
	if not active(c.state) or not f.in_play() or (not forced and not touches(c.state,f.pos)):
		return
	ScenarioNull.cancel_spells(c,f)
	if not f.in_play():
		return
	var damage := 6 if f.def.role in ["wizard","apprentice"] else 4
	c.emit("sinkhole_contact",{"id":f.id,"amount":damage})
	c._hurt(f,damage,f,false)


static func activation(c: GameController,f: Figure) -> void:
	contact(c,f)
	record_xp(c,f)


static func _award(c: GameController,f: Figure,key: String) -> void:
	var flags: Dictionary=c.state.scenario_data.get("sinkhole_xp_flags",{})
	var id := "%d:%s"%[f.id,key]
	if flags.has(id):
		return
	flags[id]=true
	c.state.scenario_data["sinkhole_xp_flags"]=flags
	c.emit("sinkhole_xp",{"id":f.id,"side":f.original_side,"xp":20,"reason":key})


static func record_xp_at(c: GameController,f: Figure,at: Vector2) -> void:
	if active(c.state) and f.in_play() and f.original_side>=0 and f.def.role in ["wizard","apprentice"] and distance(c.state,at)<=8.0:
		_award(c,f,"near_orb")


static func record_xp(c: GameController,f: Figure) -> void:
	record_xp_at(c,f,f.pos)
	if not active(c.state) or not f.in_play() or f.original_side<0 or f.def.role not in ["wizard","apprentice"]:
		return
	for other in Contact.enemies_of(c.state.figures,f):
		if other.def.id=="nullman":
			_award(c,f,"nullman_combat")


## Explicit optional resistance; the end-turn default is to accept the pull.
static func pull(c: GameController,f: Figure,resist: String="") -> void:
	var s := c.state
	if not active(s) or not f.in_play() or f.def.id=="nullman":
		return
	if resist in ["fight","will"]:
		var raw := c.dice.d20()
		var mod := (f.effective_fight()+MagicEquipment.bonus(f,"fight_test")) if resist=="fight" else f.effective_will()
		var passed := StatRoll.succeeds(raw,mod+f.roll_penalty(),20)
		c.emit("sinkhole_resist",{"id":f.id,"stat":resist,"roll":raw,"success":passed})
		if passed:
			return
		c._hurt(f,2,f,false)
		if not f.in_play():
			return
	var origin := f.pos
	var direction := (center(s)-origin).normalized()
	if direction.is_zero_approx() or touches(s,origin):
		return
	var target := origin+direction*minf(1.0,distance(s,origin))
	var last := origin
	for i in range(1,5):
		var at := origin.lerp(target,float(i)/4.0)
		if not s.board.can_stand(at,Figure.BASE_RADIUS):
			break
		var occupied := false
		for other in s.figures:
			if other!=f and other.in_play() and absf(other.elevation-s.board.height_at(at))<0.5 and other.pos.distance_to(at)<Contact.OVERLAP:
				occupied=true
				break
		if occupied:
			break
		last=at
	if last.is_equal_approx(origin):
		return
	f.pos=last
	f.elevation=s.board.height_at(last)
	f.disengaged.clear()
	for other in s.figures:
		other.disengaged.erase(f.id)
	c.emit("forced_relocation",{"id":f.id,"from":origin,"at":last,"height":f.elevation})
	contact(c,f)
	record_xp(c,f)


static func end_turn(c: GameController) -> void:
	var s := c.state
	if not active(s):
		return
	var units: Array[Figure]=[]
	for f in s.figures:
		if f.in_play():
			units.append(f)
	units.sort_custom(func(a: Figure,b: Figure) -> bool:
		return a.pos.distance_squared_to(center(s))<b.pos.distance_squared_to(center(s)))
	for f in units:
		pull(c,f)
	for token in s.treasures:
		if not token.on_ground():
			continue
		var d := distance(s,token.pos,TreasureRules.TOKEN_RADIUS)
		if d<=1.0:
			c._loot.lose(token)
		else:
			token.pos+=(center(s)-token.pos).normalized()
			c.emit("treasure_moved",{"treasure":token.id,"at":token.pos})
	_respawn(c)


static func _respawn(c: GameController) -> void:
	var s := c.state
	for dead in s.figures.duplicate():
		if dead.original_side>=0 or dead.def.id!="nullman" or not dead.out_of_action or dead.spell_effects.has("sinkhole_replaced") or c.dice.d20()<17:
			continue
		var best: Variant=null
		var score := INF
		var grid := MoveGrid.new(s.board,null,s.figures)
		var origin := MovePlanner.node_at(center(s))
		for dx in range(-7,8):
			for dy in range(-7,8):
				var n := origin+Vector2i(dx,dy)
				var at := MoveGrid.to_pos(n)
				var radius := at.distance_to(center(s))
				if radius<2.0-0.001 or radius>3.0 or not grid.open(n):
					continue
				for target in s.figures:
					if target.side>=0 and target.in_play():
						var value := at.distance_squared_to(target.pos)+100.0*(radius-2.0)
						if value<score:
							best=n
							score=value
		if best!=null:
			dead.spell_effects["sinkhole_replaced"]=true
			c._encounters._spawn_at("nullman",MoveGrid.to_pos(best))
