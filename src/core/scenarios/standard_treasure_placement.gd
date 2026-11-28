class_name StandardTreasurePlacement
extends RefCounted
## Core pp. 38–39. Seeded setup before deployment, never during a loaded battle.
## Authored special objectives keep their first token; ordinary tables use the centre.
const FREE_BOARDS := ["frozen_ruins", "sunken_streets", "worm_hunts", "genie_in_the_bottle"]
const ANCHORED := ["dreams_well", "underground_library", "silent_tower"]

static func enabled(s: GameState) -> bool:
	return s.treasures.size()==5 and (s.board.id in FREE_BOARDS or s.scenario_special in ANCHORED)

static func world(s: GameState,t: TreasureToken) -> Vector3:
	return Vector3(t.pos.x,TreasureRules.token_height(s,t),t.pos.y)

static func prepare(s: GameState,dice: Dice) -> bool:
	if not enabled(s) or s.turn!=0 or s.scenario_data.get("standard_treasure_ready",false):
		return true
	for t in s.treasures:
		if not t.on_ground() or t.ever_collected:
			return true
	var center:=s.board.size*0.5
	var candidates:=_candidates(s)
	var anchor: Dictionary={"at":s.treasures[0].pos,"surface":s.treasures[0].surface_id,"world":world(s,s.treasures[0])}
	if not s.scenario_special in ANCHORED:
		var best:=INF
		for p in candidates:
			var at: Vector2=p["at"]
			var v: Vector3=p["world"]
			var score:=at.distance_squared_to(center)+absf(v.y)*0.0001
			if score<best:
				best=score
				anchor=p
		if best==INF:
			return false
	var inner: Array[Dictionary]=[]
	var outer: Array[Dictionary]=[]
	var origin: Vector3=anchor["world"]
	for p in candidates:
		var v: Vector3=p["world"]
		var distance:=v.distance_to(origin)
		if distance>=6.0 and distance<=8.0:
			inner.append(p)
		if distance>6.0 and TreasureRules.edge_distance(s.board,p["at"])>9.0:
			outer.append(p)
	# Bounded retries; no mutations until all five positions are legal.
	for attempt in 48:
		var chosen: Array[Dictionary]=[anchor]
		for i in 4:
			var pool:=inner if i<2 else outer
			var legal: Array[Dictionary]=[]
			for p in pool:
				if _separated(p,chosen,i>=2):
					legal.append(p)
			if legal.is_empty():
				break
			chosen.append(legal[dice.pick(legal.size())])
		if chosen.size()!=5:
			continue
		for i in 5:
			s.treasures[i].pos=chosen[i]["at"]
			s.treasures[i].surface_id=chosen[i]["surface"]
		s.scenario_data["standard_treasure_ready"]=true
		return true
	return false

static func _separated(p: Dictionary,chosen: Array[Dictionary],strict: bool) -> bool:
	var at: Vector3=p["world"]
	for other in chosen:
		var distance:=at.distance_to(other["world"])
		if distance<6.0 or (strict and distance<=6.0):
			return false
	return true

static func _candidates(s: GameState) -> Array[Dictionary]:
	var out: Array[Dictionary]=[]
	var center:=s.board.size*0.5
	var anchor:=s.treasures[0].pos if s.scenario_special in ANCHORED else center
	var layout: FloorLayout=null
	if not s.board.floor_layout.is_empty():
		layout=s.board.floor_geometry()
	var deck_indices: Array[int]=[]
	if layout!=null:
		for i in layout.surfaces.size():
			if not layout.surfaces[i].id.begins_with("climb:"):
				deck_indices.append(i)
	# Sample the canonical half-inch grid; figure-sized clearance is intentionally
	# conservative so every selected treasure has a usable standing position.
	for x in range(1,floori(s.board.size.x*2.0)):
		for y in range(1,floori(s.board.size.y*2.0)):
			var at:=Vector2(x,y)*0.5
			if at.distance_to(anchor)>8.0 and TreasureRules.edge_distance(s.board,at)<=9.0:
				continue
			if layout==null:
				if s.board.can_stand(at,Figure.BASE_RADIUS):
					out.append({"at":at,"surface":"","world":Vector3(at.x,s.board.height_at(at),at.y)})
				continue
			if s.board.over_void(at,Figure.BASE_RADIUS):
				continue
			for i in deck_indices:
				var n:=Vector3i(x,y,i)
				if not layout.standable(n):
					continue
				out.append({"at":at,"surface":layout.surface_id(n),"world":layout.world(n)})
	return out


## During the interactive setup, only already placed tokens constrain choices.
static func options(s: GameState,candidates: Array[Dictionary],index: int) -> Array[Dictionary]:
	var chosen: Array[Dictionary]=[]
	for i in index:
		chosen.append({"at":s.treasures[i].pos,"surface":s.treasures[i].surface_id,"world":world(s,s.treasures[i])})
	return _legal(s,candidates,index,chosen)

static func _legal(s: GameState,candidates: Array[Dictionary],index: int,chosen: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	var anchor: Vector3=chosen[0]["world"]
	for p in candidates:
		var at: Vector3=p["world"]
		var distance:=at.distance_to(anchor)
		if index<3 and (distance<6.0 or distance>8.0):
			continue
		if index>=3 and TreasureRules.edge_distance(s.board,p["at"])<=9.0:
			continue
		if _separated(p,chosen,index>=3):
			result.append(p)
	return result

## Lock the selected position, then find a valid completion. Never change
## earlier placements, even if a cramped board forces another selection.
static func choose(s: GameState,dice: Dice,candidates: Array[Dictionary],index: int,p: Dictionary) -> bool:
	if index not in [1,3] or not options(s,candidates,index).has(p):
		return false
	var fixed: Array[Dictionary]=[]
	for i in index:
		fixed.append({"at":s.treasures[i].pos,"surface":s.treasures[i].surface_id,"world":world(s,s.treasures[i])})
	fixed.append(p)
	for attempt in 48:
		var chosen: Array[Dictionary]=fixed.duplicate()
		for i in range(index+1,5):
			var legal:=_legal(s,candidates,i,chosen)
			if legal.is_empty():
				break
			chosen.append(legal[dice.pick(legal.size())])
		if chosen.size()!=5:
			continue
		for i in range(index,5):
			s.treasures[i].pos=chosen[i]["at"]
			s.treasures[i].surface_id=chosen[i]["surface"]
		return true
	return false
