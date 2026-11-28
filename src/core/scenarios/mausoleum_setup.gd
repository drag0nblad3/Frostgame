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
	# Every real deck is eligible, but never a restricted hanging position.
	var bounds:=rect.grow(9.0)
	for z in layout.surfaces.size():
		var surface:=layout.surfaces[z]
		if surface.id.begins_with("climb:"):
			continue
		var area:=bounds.intersection(surface.rect)
		if not area.has_area():
			continue
		for x in range(maxi(1,ceili(area.position.x*2.0)),mini(floori(s.board.size.x*2.0),floori(area.end.x*2.0)+1)):
			for y in range(maxi(1,ceili(area.position.y*2.0)),mini(floori(s.board.size.y*2.0),floori(area.end.y*2.0)+1)):
				var n:=Vector3i(x,y,z)
				var at:=layout.point(n)
				if Geom.point_rect_distance(at,rect)>9.0 or not layout.standable(n) or s.board.over_void(at,Figure.BASE_RADIUS):
					continue
				var height:=layout.height(n)
				if _occupied(s,index,at,height,TreasureRules.TOKEN_RADIUS):
					continue
				var p:=_guard_option(s,index,layout,n)
				if not p.is_empty():
					result.append(p)
	return result


static func _occupied(s: GameState,index: int,at: Vector2,height: float,radius: float) -> bool:
	for i in index:
		var t:=s.treasures[i]
		if absf(TreasureRules.token_height(s,t)-height)<0.5 and t.pos.distance_to(at)<TreasureRules.TOKEN_RADIUS+radius:
			return true
	var creatures:=s.side_figures(-1)
	for i in index:
		var f:=creatures[i]
		var separation:=Contact.OVERLAP if radius==Figure.BASE_RADIUS else Figure.BASE_RADIUS+radius
		if absf(f.elevation-height)<0.5 and f.pos.distance_to(at)<separation:
			return true
	return false


static func _guard_option(s: GameState,index: int,layout: FloorLayout,n: Vector3i) -> Dictionary:
	var at:=layout.point(n)
	var height:=layout.height(n)
	for d: Vector2i in [Vector2i(0,2),Vector2i(2,0),Vector2i(0,-2),Vector2i(-2,0),Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]:
		var guard:=n+Vector3i(d.x,d.y,0)
		var guard_at:=layout.point(guard)
		if not layout.standable(guard) or s.board.over_void(guard_at,Figure.BASE_RADIUS):
			continue
		var guard_height:=layout.height(guard)
		if absf(guard_height-height)>=0.5 or guard_at.distance_to(at)<Figure.BASE_RADIUS+TreasureRules.TOKEN_RADIUS:
			continue
		if _occupied(s,index,guard_at,guard_height,Figure.BASE_RADIUS):
			continue
		# Do not put a guard across a wall or a gap on the same deck.
		var clear:=true
		for step in range(1,4):
			var midpoint:=layout.world(n).lerp(layout.world(guard),float(step)/4.0)
			if not layout.surfaces[n.z].contains(Vector2(midpoint.x,midpoint.z),Figure.BASE_RADIUS) or not layout.clearance(midpoint,Figure.BASE_RADIUS,1.6):
				clear=false
				break
		if clear:
			return {"at":at,"world":layout.world(n),"height":height,"surface":layout.surface_id(n),"guard":guard_at,"guard_height":guard_height,"guard_surface":layout.surface_id(guard)}
	return {}


static func apply(s: GameState,index: int,p: Dictionary) -> void:
	var token:=s.treasures[index]
	token.pos=p["at"]
	token.surface_id=p["surface"]
	var guard:=s.side_figures(-1)[index]
	guard.pos=p["guard"]
	guard.surface_id=str(p["guard_surface"])
	guard.elevation=float(p["guard_height"])

static func choose(s: GameState,dice: Dice,p: Dictionary) -> bool:
	if not options(s,4).has(p):
		return false
	var token:=s.treasures[4]
	var guard:=s.side_figures(-1)[4]
	var old:={"at":token.pos,"surface":token.surface_id,"guard":guard.pos,"guard_height":guard.elevation,"guard_surface":guard.surface_id}
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
