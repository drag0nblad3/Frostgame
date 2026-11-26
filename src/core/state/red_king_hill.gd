class_name RedKingHill
extends RefCounted
## Scenario nine, Red King pp.48–49. Four rule-defined slopes.
const ID := "red_king_hill"
const TWO_PLAYER := [20,18,16,14,12,8,4,1]
const MULTIPLAYER := [20,19,17,16,14,11,8,4]


static func active(s: GameState) -> bool:
	return s!=null and s.scenario_special==ID


static func cracked(s: GameState) -> bool:
	return active(s) and bool(s.scenario_data.get("hill_cracked",false))


static func is_herald(s: GameState,f: Figure) -> bool:
	return active(s) and f!=null and f.def.id=="red_king_herald"


static func guarded(s: GameState,t: TreasureToken) -> bool:
	if not active(s) or t==null or not t.central or not t.on_ground():
		return false
	for f in s.figures:
		if is_herald(s,f) and f.in_play() and f.pos.distance_to(t.pos)<=Figure.BASE_RADIUS+TreasureRules.TOKEN_RADIUS+0.01:
			return true
	return false


static func priority(c: GameController,rolls: Array) -> void:
	var s := c.state
	if not active(s) or cracked(s) or rolls.is_empty():
		return
	var thresholds := TWO_PLAYER if s.side_count()<=2 else MULTIPLAYER
	if int(rolls.max())>=int(thresholds[clampi(s.turn+1,0,7)]):
		transform(c)


static func transform(c: GameController) -> void:
	var s := c.state
	if not active(s) or cracked(s):
		return
	s.scenario_data["hill_cracked"]=true
	var center := s.board.size*0.5
	var lines: Array[Dictionary]=[
		{"a":Vector2.ZERO,"b":s.board.size,"sight":true,"sight_exempt_center":center,"sight_exempt_radius":3.0},
		{"a":Vector2(s.board.size.x,0),"b":Vector2(0,s.board.size.y),"sight":true,"sight_exempt_center":center,"sight_exempt_radius":3.0}]
	s.board.set_boundaries(lines)
	c.emit("boundary_changed",{})
	c.emit("hill_crack",{})
	for f in s.figures:
		if not f.in_play() or f.side<0:
			continue
		if f.def.role in ["wizard","apprentice"]:
			c.emit("hill_xp",{"id":f.id,"side":f.side,"xp":20 if f.def.role=="wizard" else 10})
		if _straddles(s,f.pos):
			_shift_from_seam(c,f)


static func _straddles(s: GameState,at: Vector2) -> bool:
	for line in s.board.boundaries:
		if Geometry2D.get_closest_point_to_segment(at,line["a"],line["b"]).distance_to(at)<Figure.BASE_RADIUS-0.001:
			return true
	return false


static func _shift_from_seam(c: GameController,f: Figure) -> void:
	var grid := MoveGrid.new(c.state.board,f,c.state.figures)
	var origin := MovePlanner.node_at(f.pos)
	var best: Variant=null
	var score := INF
	for x in range(-6,7):
		for y in range(-6,7):
			var n := origin+Vector2i(x,y)
			var at := MoveGrid.to_pos(n)
			var d := f.pos.distance_squared_to(at)
			if not _straddles(c.state,at) and d<score and grid.open(n):
				best=n
				score=d
	if best!=null:
		_place(c,f,MoveGrid.to_pos(best))


static func airborne(f: Figure) -> bool:
	return f.def.traits.has("flying") or f.def.traits.has("levitate") or f.spell_effects.has("levitate")


static func before_move(c: GameController,f: Figure) -> bool:
	if not cracked(c.state) or f.moves_taken==0 or airborne(f):
		return true
	if balance(c,f):
		return true
	f.actions_left=maxi(0,f.actions_left-1)
	f.moves_taken+=1
	return false


static func balance(c: GameController,f: Figure) -> bool:
	if not cracked(c.state) or not f.in_play() or airborne(f):
		return true
	var raw := c.dice.d20()
	var passed := StatRoll.succeeds(raw,f.effective_move()+f.roll_penalty(),16)
	c.emit("hill_balance",{"id":f.id,"roll":raw,"success":passed})
	if not passed:
		fall(c,f)
	return passed


static func downhill(s: GameState,at: Vector2) -> Vector2:
	var delta := at-s.board.size*0.5
	if absf(delta.x)>=absf(delta.y):
		return Vector2.LEFT if delta.x<0 else Vector2.RIGHT
	return Vector2.UP if delta.y<0 else Vector2.DOWN


static func fall(c: GameController,f: Figure) -> void:
	if not cracked(c.state) or not f.in_play() or airborne(f):
		return
	var s := c.state
	var origin := f.pos
	var direction := downhill(s,origin)
	var last := origin
	for i in range(1,25):
		var at := origin+direction*(0.25*i)
		if not s.board.can_stand(at,Figure.BASE_RADIUS):
			break
		var blocked := false
		for p in s.board.pieces:
			if not p.kind.ground_surface and p.kind.height>0.5 and p.rect.grow(Figure.BASE_RADIUS).has_point(at):
				blocked=true
				break
		if blocked:
			break
		var occupied := false
		for other in s.figures:
			if other!=f and other.in_play() and other.pos.distance_to(at)<Contact.OVERLAP and absf(other.elevation-s.board.height_at(at))<0.5:
				occupied=true
				break
		if not occupied and not TerrainMagic.ward_blocks(s.board,f,at):
			last=at
	if not last.is_equal_approx(origin):
		_place(c,f,last)
		c._magic.terrain.trigger_landing(f)
	if not f.in_play():
		return
	for id in f.carried_treasures():
		var raw := c.dice.d20()
		if not StatRoll.succeeds(raw,f.effective_will()+f.roll_penalty(),12):
			var margin := Vector2.ONE*TreasureRules.TOKEN_RADIUS
			var desired := (origin+Vector2.RIGHT.rotated(TAU*float(c.dice.pick(20))/20.0)*3.0).clamp(margin,s.board.size-margin)
			c._loot._drop(f,desired if s.board.can_stand(desired,TreasureRules.TOKEN_RADIUS) else origin,id)


static func _place(c: GameController,f: Figure,at: Vector2) -> void:
	var old := f.pos
	f.pos=at
	f.elevation=c.state.board.height_at(at)
	f.disengaged.clear()
	for other in c.state.figures:
		other.disengaged.erase(f.id)
	c.emit("forced_relocation",{"id":f.id,"from":old,"at":at,"height":f.elevation})


static func play_herald(c: GameController,f: Figure) -> void:
	if not f.in_play() or f.actions_left<=0:
		return
	var enemy := CreatureBot.weakest(c.state,f)
	if enemy!=null and c.can_fight(enemy.id):
		c.fight(enemy.id)
		return
	var center := c.state.board.size*0.5
	if not f.pos.is_equal_approx(center) and c.can_move():
		var r := c.reach()
		var best: Variant=null
		var score := f.pos.distance_squared_to(center)
		for n: Vector2i in r.nodes():
			var d := MoveGrid.to_pos(n).distance_squared_to(center)
			if d<score-0.001:
				best=n
				score=d
		if best!=null:
			c.move_to(best)
	if not f.in_play() or c.awaiting_reaction() or not c.can_act():
		return
	enemy=CreatureBot.weakest(c.state,f)
	if enemy!=null and c.can_fight(enemy.id):
		c.fight(enemy.id)
		return
	var target := CreatureBot._blast_target(c,f)
	if target!=null:
		c._spend(f)
		c._magic._shot(f,target,3,f.pos,true,true,"elemental_blast")
