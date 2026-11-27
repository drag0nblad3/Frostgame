class_name RedKingTethers
extends RefCounted
## Red King scenario ten. Reserve objective IDs for stable checkpoint and UI references.
const ID := "red_king_tethers"


static func active(s: GameState) -> bool:
	return s!=null and s.scenario_special==ID


static func pylon(f: Figure) -> bool:
	return f!=null and f.def.traits.has("pylon")


static func remaining(s: GameState) -> int:
	var count := 0
	for f in s.figures:
		if pylon(f) and f.in_play():
			count+=1
	return count


static func setup(s: GameState) -> void:
	var ids := {}
	for f in s.figures:
		if not pylon(f):
			continue
		var token := TreasureToken.new(s.treasures.size(),f.pos)
		token.central=false
		token.lost=true
		token.bonus_gold=20
		s.treasures.append(token)
		ids[f.id]=token.id
	s.scenario_data["pylon_tokens"]=ids


static func destroyed(c: GameController,f: Figure,by: Figure) -> void:
	var s := c.state
	if not active(s) or not pylon(f):
		return
	var token := s.treasure(int(s.scenario_data.get("pylon_tokens",{}).get(f.id,-1)))
	if token==null or not token.lost:
		return
	token.lost=false
	token.pos=f.pos
	c.emit("pylon_destroyed",{"id":f.id,"treasure":token.id,"at":token.pos})
	if by!=null and by.side>=0:
		c.emit("tether_xp",{"side":by.side,"xp":50})
	if remaining(s)==0:
		s.board.edge_links.clear()
		s.board.set_boundaries([])
		c.emit("boundary_changed",{})
		c.emit("tethers_restored",{})


static func arrival(roll: int) -> String:
	if roll<=15:
		return ""
	return "hrut_warrior" if roll<=17 else ("hrut_stinger" if roll==18 else ("hrut_longhammer" if roll==19 else "hrut_darter"))


static func end_turn(c: GameController) -> void:
	var s := c.state
	if not active(s) or remaining(s)==0:
		return
	for f in s.figures.duplicate():
		if not pylon(f) or not f.in_play():
			continue
		var id := arrival(c.dice.d20())
		if id.is_empty() or not s.creature_db.available(id):
			continue
		var grid := MoveGrid.new(s.board,null,s.figures)
		var center := MovePlanner.node_at(f.pos)
		var best: Variant=null
		var score := INF
		for x in range(-5,6):
			for y in range(-5,6):
				var n := center+Vector2i(x,y)
				var at := MoveGrid.to_pos(n)
				var distance: float=at.distance_to(f.pos)
				if distance<1.0-0.001 or distance>2.5 or not grid.open(n):
					continue
				for target in s.figures:
					if target.side>=0 and target.in_play():
						var d: float=distance*100.0+at.distance_to(target.pos)
						if d<score:
							best=n
							score=d
		if best!=null:
			c._encounters._spawn_at(id,MoveGrid.to_pos(best))
	if s.turn==2:
		transform(c)


static func transform(c: GameController) -> void:
	var s := c.state
	if not active(s) or remaining(s)==0 or s.scenario_data.get("tether_crack",false):
		return
	s.scenario_data["tether_crack"]=true
	var lines: Array[Dictionary]=[]
	for i in [1,2]:
		var x := s.board.size.x*float(i)/3.0
		lines.append({"a":Vector2(x,0),"b":Vector2(x,s.board.size.y),"movement":true,"sight":true,"allow_spells":["plane_walk"]})
	s.board.edge_links=BoardTopology.mobius(s.board.size,s.order[0] if not s.order.is_empty() else 0)
	s.board.set_boundaries(lines)
	c.emit("boundary_changed",{})
	c.emit("tethers_crack",{})
	for f in s.figures:
		if f.side>=0 and f.in_play() and f.def.role in ["wizard","apprentice"]:
			c.emit("tether_xp",{"side":f.side,"xp":20 if f.def.role=="wizard" else 10})
