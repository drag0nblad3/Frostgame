class_name DeploymentRules
extends RefCounted
## Two-player setup zones (core p.39; Red King pp.29,34,43,53,57).
## Positions are measured at the base centre on the half-inch lattice.


static func kind(s: GameState) -> String:
	if s.side_count()!=2 or s.board.id=="training_yard" or RedKingMind.active(s):
		return "fixed"
	if RedKingRingworld.active(s):
		return "ring"
	if RedKingVeil.active(s):
		return "veil"
	if RedKingFire.active(s) or RedKingHerded.active(s) or RedKingBridge.active(s):
		return "corner"
	if s.scenario_special=="underground_library":
		return "door"
	return "edge"


static func choices(s: GameState,previous: int=-1) -> Array[int]:
	var options: Array[int]=[]
	match kind(s):
		"fixed": return options
		"veil","ring": options.assign([0])
		"corner": options.assign([0,1] if previous<0 else [1-previous])
		_:
			# The authored investigation tent has two opposite entrances.
			if previous>=0:
				options.append((previous+2)%4)
			elif RedKingInvestigations.active(s) or s.scenario_special=="dreams_well":
				options.assign([0,2])
			else:
				options.assign([0,1,2,3])
	return options


static func label(s: GameState,zone: int) -> String:
	match kind(s):
		"corner": return "Start left corner" if zone==0 else "Start right corner"
		"ring": return "Around wizard"
		"veil": return "Player edge"
		"door": return ["Near doorway","Right doorway","Far doorway","Left doorway"][zone]
		_: return ["Near edge","Right edge","Far edge","Left edge"][zone]


static func edge_point(size: Vector2,edge: int) -> Vector2:
	return [Vector2(size.x*0.5,0),Vector2(size.x,size.y*0.5),Vector2(size.x*0.5,size.y),Vector2(0,size.y*0.5)][edge]


static func zone(s: GameState,choice: int,at: Vector2,wizard: Vector2=Vector2.INF,is_wizard: bool=false) -> bool:
	var size:=s.board.size
	match kind(s):
		"fixed": return false
		"ring":
			if is_wizard:
				return at.distance_to(size*0.5)<=8.0
			return is_finite(wizard.x) and at.distance_to(wizard)<=3.0
		"veil": return at.y<=Figure.BASE_RADIUS+0.01
		"corner":
			var corner:=Vector2(0 if choice==0 else size.x,0)
			return at.distance_to(corner)<=(4.0 if RedKingBridge.active(s) else 6.0)
		"door": return at.distance_to(edge_point(size,choice))<=6.0
		_:
			var along:=at.x if choice%2==0 else at.y
			var length:=size.x if choice%2==0 else size.y
			var depth: float=[at.y,size.x-at.x,size.y-at.y,at.x][choice]
			return depth<=3.0 and along>=6.0 and along<=length-6.0


static func support(s: GameState,at: Vector2) -> Dictionary:
	if not s.board.contains(at,Figure.BASE_RADIUS) or s.board.over_void(at,Figure.BASE_RADIUS):
		return {}
	if s.board.floor_layout.is_empty():
		if not s.board.can_stand(at,Figure.BASE_RADIUS):
			return {}
		return {"at":at,"height":s.board.height_at(at),"surface":""}
	var n: Variant=BattlePlacement.support(s,at,"street",Figure.BASE_RADIUS,1.6,false)
	if n==null:
		return {}
	var l:=s.board.floor_geometry()
	return {"at":at,"height":l.height(n),"surface":l.surface_id(n)}


static func legal(s: GameState,f: Figure,point: Dictionary,ignored: Array) -> bool:
	if point.is_empty():
		return false
	var at: Vector2=point["at"]
	var h:=float(point["height"])
	for other in s.figures:
		if other==f or not other.in_play() or ignored.has(other.id) or other.ring_side!=f.ring_side:
			continue
		var distance:=Vector3(at.x,h,at.y).distance_to(Vector3(other.pos.x,other.elevation,other.pos.y))
		if kind(s)=="ring" and other.side>=0 and other.side!=f.side and distance<7.0-0.001:
			return false
		if absf(h-other.elevation)<0.5 and at.distance_to(other.pos)<Contact.OVERLAP:
			return false
	for t in s.treasures:
		if t.on_ground() and t.ring_side==f.ring_side and absf(TreasureRules.token_height(s,t)-h)<0.5 and t.pos.distance_to(at)<Figure.BASE_RADIUS+TreasureRules.TOKEN_RADIUS:
			return false
	return true


static func options(s: GameState,f: Figure,choice: int,ignored: Array,wizard: Vector2=Vector2.INF) -> Array[Dictionary]:
	var out: Array[Dictionary]=[]
	for x in range(1,floori(s.board.size.x*2.0)):
		for y in range(1,floori(s.board.size.y*2.0)):
			var at:=Vector2(x,y)*0.5
			if not zone(s,choice,at,wizard,f.def.role=="wizard"):
				continue
			var point:=support(s,at)
			if legal(s,f,point,ignored):
				out.append(point)
	return out
