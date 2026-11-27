class_name ForcedRelocation
extends RefCounted
## Find a nearby legal landing without tracing a walking path.
## For explicit floors, choose legal support without silently changing deck.
static func destination(s: GameState,f: Figure,desired: Vector2) -> Vector2:
	var b := s.board
	var margin := Vector2.ONE*Figure.BASE_RADIUS
	var target := desired.clamp(margin,b.size-margin)
	var grid := MoveGrid.new(b,f,s.figures)
	var center := MovePlanner.node_at(target)
	# Search adjacent half-inch lattice positions in order of actual distance.
	var best := f.pos
	var best_distance := INF
	for radius in range(0,13):
		for x in range(-radius,radius+1):
			for y in range(-radius,radius+1):
				if maxi(absi(x),absi(y))!=radius:
					continue
				var node := center+Vector2i(x,y)
				var at := MoveGrid.to_pos(node)
				var distance := at.distance_squared_to(target)
				if distance<best_distance and grid.open(node) and not BattleBoundary.blocks_end(b.boundaries,at):
					best=at
					best_distance=distance
		if best_distance<INF and sqrt(best_distance)<float(radius)*MoveGrid.STEP:
			break
	return best


static func relocate(c: GameController,f: Figure,desired: Vector2) -> bool:
	if not f.in_play():
		return false
	if RedKingBridge.forced_void(c,f,desired,f.pos):
		return true
	if not c.state.board.floor_layout.is_empty():
		if RedKingHerded.contact(c,f,desired) or RedKingVeil.touch(c,f,desired):
			return true
		var node: Variant=destination_floor(c.state,f,desired)
		if node==null:
			return false
		return apply_floor(c,f,node)
	var at := destination(c.state,f,desired)
	if RedKingHerded.contact(c,f,at) or RedKingVeil.touch(c,f,at):
		return true
	RedKingFire.portal_contact(c,f,at,at,{})
	if not f.in_play():
		return true
	if at.is_equal_approx(f.pos):
		return false
	var old := f.pos
	f.pos=at
	f.elevation=c.state.board.height_at(at)
	RedKingMind.collect(c,f,at,at)
	f.disengaged.clear()
	for other in c.state.figures:
		other.disengaged.erase(f.id)
	c._displacement.clear()
	c.emit("forced_relocation",{"id":f.id,"from":old,"at":at,"height":f.elevation})
	RedKingSinkhole.contact(c,f)
	RedKingSinkhole.record_xp(c,f)
	return true


## Forced relocation is not a voluntary movement action. Prefer a legal
## location on the original support, or a coplanar adjacent support.
static func destination_floor(s: GameState,f: Figure,desired: Vector2,accept: Callable=Callable(),ignore_ids: Array=[],reserved: Array=[]) -> Variant:
	var layout:=s.board.floor_geometry()
	var margin:=Vector2.ONE*Figure.BASE_RADIUS
	var target:=desired.clamp(margin,s.board.size-margin)
	var best: Variant=null
	var score:=INF
	for n in BattlePlacement.nodes(s.board,target,6.0):
		var at:=layout.point(n)
		if at.distance_to(target)>6.001 or absf(layout.height(n)-f.elevation)>=0.5 or (accept.is_valid() and not accept.call(at)):
			continue
		var value:=at.distance_squared_to(target)+(0.001 if layout.surface_id(n)!=f.surface_id else 0.0)
		if value>=score or not BattlePlacement.floor_open(s,n,f,Figure.BASE_RADIUS,1.6,true,null,-1,ignore_ids):
			continue
		var blocked:=false
		for reservation: Dictionary in reserved:
			var world: Vector3=reservation["world"]
			if int(reservation["ring"])==f.ring_side and absf(world.y-layout.height(n))<0.5 and Vector2(world.x,world.z).distance_to(at)<Contact.OVERLAP:
				blocked=true
				break
		if not blocked:
			best=n
			score=value
	return best


static func apply_floor(c: GameController,f: Figure,n: Vector3i) -> bool:
	var layout:=c.state.board.floor_geometry()
	if not BattlePlacement.floor_open(c.state,n,f):
		return false
	var from:=Vector3(f.pos.x,f.elevation,f.pos.y)
	var to:=layout.world(n)
	if from.is_equal_approx(to) and f.surface_id==layout.surface_id(n):
		return false
	var old:=f.surface_id
	f.pos=layout.point(n)
	f.elevation=layout.height(n)
	f.surface_id=layout.surface_id(n)
	f.disengaged.clear()
	for other in c.state.figures:
		other.disengaged.erase(f.id)
	c._displacement.clear()
	c.emit("layered_move",{"id":f.id,"path":PackedVector3Array([from,to]),"surfaces":[old,f.surface_id],"cost":0.0,"teleport":true})
	RedKingFire.portal_contact(c,f,f.pos,f.pos,{},f.elevation,f.elevation)
	RedKingMind.collect(c,f,f.pos,f.pos,f.elevation,f.elevation)
	if f.in_play():
		c._magic.terrain.trigger_landing(f)
	return true


## Plan all simultaneous shifts before mutating figures, so no participant
## blocks another's vacated position and no two landings overlap.
static func group_floor(c: GameController,figures: Array[Figure],targets: Dictionary) -> bool:
	var s:=c.state
	var layout:=s.board.floor_geometry()
	var ids: Array[int]=[]
	for f in figures:
		ids.append(f.id)
	var planned: Dictionary={}
	var reserved: Array=[]
	var origins: Dictionary={}
	for f in figures:
		var desired: Vector2=targets[f.id]
		var n: Variant=destination_floor(s,f,desired,Callable(),ids,reserved)
		if n==null:
			return false
		planned[f.id]=n
		reserved.append({"world":layout.world(n),"ring":f.ring_side})
		origins[f.id]={"world":Vector3(f.pos.x,f.elevation,f.pos.y),"surface":f.surface_id}
	for f in figures:
		var n: Vector3i=planned[f.id]
		f.pos=layout.point(n)
		f.elevation=layout.height(n)
		f.surface_id=layout.surface_id(n)
		f.disengaged.clear()
	for f in figures:
		for other in s.figures:
			other.disengaged.erase(f.id)
		var old: Dictionary=origins[f.id]
		var path:=PackedVector3Array([old["world"],Vector3(f.pos.x,f.elevation,f.pos.y)])
		c.emit("layered_move",{"id":f.id,"path":path,"surfaces":[old["surface"],f.surface_id],"cost":0.0,"teleport":true})
	return true
