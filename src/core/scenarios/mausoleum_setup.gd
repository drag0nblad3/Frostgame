class_name MausoleumSetup
extends RefCounted
## Core p.142: four corner tokens and door guards stay fixed; each warband
## places one additional treasure within nine inches of the building.
static func enabled(s: GameState) -> bool:
	return s.board.id=="mausoleum" and s.treasures.size()==6 and s.side_figures(-1).size()==6 and s.turn==0

static func building(s: GameState) -> Rect2:
	for p in s.board.pieces:
		if p.kind.id=="ruin" and p.rect.has_point(s.board.size*0.5):
			return p.rect
	return Rect2()

static func options(s: GameState,index: int) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if not enabled(s) or index not in [4,5]:
		return result
	var rect:=building(s)
	if not rect.has_area():
		return result
	var layout:=s.board.floor_geometry()
	var street:=layout.index_of("street")
	if street<0:
		return result
	var creatures:=s.side_figures(-1)
	for x in range(maxi(1,ceili((rect.position.x-9.0)*2.0)),mini(floori(s.board.size.x*2.0),floori((rect.end.x+9.0)*2.0)+1)):
		for y in range(maxi(1,ceili((rect.position.y-9.0)*2.0)),mini(floori(s.board.size.y*2.0),floori((rect.end.y+9.0)*2.0)+1)):
			var n:=Vector3i(x,y,street)
			var at:=layout.point(n)
			if Geom.point_rect_distance(at,rect)>9.0 or not layout.standable(n) or s.board.over_void(at,Figure.BASE_RADIUS):
				continue
			var blocked:=false
			for i in index:
				if s.treasures[i].pos.distance_to(at)<2.0*TreasureRules.TOKEN_RADIUS:
					blocked=true
					break
			if blocked:
				continue
			for i in (4 if index==4 else 5):
				if creatures[i].pos.distance_to(at)<Figure.BASE_RADIUS+TreasureRules.TOKEN_RADIUS:
					blocked=true
					break
			if blocked:
				continue
			# Adjacent guard: physical base clearance and legal ground support.
			for d: Vector2i in [Vector2i(0,2),Vector2i(2,0),Vector2i(0,-2),Vector2i(-2,0),Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]:
				var guard:=n+Vector3i(d.x,d.y,0)
				if not layout.standable(guard) or s.board.over_void(layout.point(guard),Figure.BASE_RADIUS):
					continue
				var guard_at:=layout.point(guard)
				if guard_at.distance_to(at)<Figure.BASE_RADIUS+TreasureRules.TOKEN_RADIUS:
					continue
				blocked=false
				for i in index:
					if s.treasures[i].pos.distance_to(guard_at)<Figure.BASE_RADIUS+TreasureRules.TOKEN_RADIUS:
						blocked=true
						break
				if blocked:
					continue
				for i in (4 if index==4 else 5):
					if creatures[i].pos.distance_to(guard_at)<Contact.OVERLAP:
						blocked=true
						break
				if not blocked:
					result.append({"at":at,"world":layout.world(n),"height":layout.height(n),"surface":"street","guard":guard_at,"guard_height":layout.height(guard)})
					break
	return result

static func apply(s: GameState,index: int,p: Dictionary) -> void:
	var token:=s.treasures[index]
	token.pos=p["at"]
	token.surface_id=p["surface"]
	var guard:=s.side_figures(-1)[index]
	guard.pos=p["guard"]
	guard.surface_id="street"
	guard.elevation=float(p["guard_height"])

static func choose(s: GameState,dice: Dice,p: Dictionary) -> bool:
	if not options(s,4).has(p):
		return false
	var token:=s.treasures[4]
	var guard:=s.side_figures(-1)[4]
	var old:={"at":token.pos,"surface":token.surface_id,"guard":guard.pos,"guard_height":guard.elevation}
	apply(s,4,p)
	var remaining:=options(s,5)
	if remaining.is_empty():
		apply(s,4,old)
		return false
	apply(s,5,remaining[dice.pick(remaining.size())])
	s.scenario_data["mausoleum_treasures_ready"]=true
	return true

static func prepare(s: GameState,dice: Dice) -> bool:
	if not enabled(s) or s.scenario_data.get("mausoleum_treasures_ready",false):
		return true
	var choices:=options(s,4)
	if choices.is_empty():
		return false
	return choose(s,dice,choices[dice.pick(choices.size())])
