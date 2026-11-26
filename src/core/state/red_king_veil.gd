class_name RedKingVeil
extends RefCounted
## Hidden scenario prototype, Red King pp.29–31.
const ID := "red_king_veil"


static func active(s: GameState) -> bool:
	return s!=null and s.scenario_special==ID


static func of(f: Figure) -> GameState:
	return f.battle_ref.get_ref() as GameState if f.battle_ref!=null else null


static func prepare(c: GameController) -> void:
	var s := c.state
	if not active(s) or s.scenario_data.has("veil_y"):
		return
	s.scenario_data["veil_y"]=12.0
	var slots: Array[Dictionary]=[]
	for edge in 2:
		for i in 3:
			slots.append({"type":"foulhorn" if i==0 else "blood_marked_berserker","edge":edge,"id":-1,"entered":false})
	s.scenario_data["veil_slots"]=slots
	_sync(c)


static func _sync(c: GameController) -> void:
	var s := c.state
	var y := float(s.scenario_data["veil_y"])
	var lines: Array[Dictionary]=[]
	if y<s.board.size.y:
		lines.append({"a":Vector2(0,y),"b":Vector2(s.board.size.x,y),"lethal":true})
	s.board.set_boundaries(lines)
	c.emit("boundary_changed",{"veil_y":y})


static func lethal(s: GameState,a: Vector2,b: Vector2) -> bool:
	if not active(s):
		return false
	var y := float(s.scenario_data.get("veil_y",12.0))
	return y<s.board.size.y and minf(a.y,b.y)<=y+Figure.BASE_RADIUS and maxf(a.y,b.y)>=y-Figure.BASE_RADIUS


static func touch(c: GameController,f: Figure,at: Vector2) -> bool:
	if not f.in_play() or not lethal(c.state,f.pos,at):
		return false
	c.emit("veil_contact",{"id":f.id})
	c._hurt(f,f.health,f,false)
	return true


static func advance(c: GameController,extra: int=0) -> void:
	var s := c.state
	if not active(s):
		return
	s.scenario_data["veil_y"]=minf(s.board.size.y,float(s.scenario_data.get("veil_y",12.0))+4.0+clampi(extra,0,3))
	_sync(c)


static func exit_allowed(s: GameState,at: Vector2,side: int) -> bool:
	return side!=1 and at.y>=s.board.size.y-Figure.BASE_RADIUS-0.01


static func xp(c: GameController,side: int) -> int:
	var value := c.state.secured_count(side)*25
	for f in c.state.figures:
		if f.original_side==side and f.exited:
			value+=60 if f.def.role=="wizard" else (40 if f.def.role=="apprentice" else 20)
	return value
