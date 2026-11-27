class_name RealityFloorEffects
extends RefCounted

static func exchange(c: GameController,selected: Array[Figure]) -> bool:
	var s:=c.state
	var layout:=s.board.floor_geometry()
	var ids: Array[int]=[]
	var origins: Array[Vector3i]=[]
	var supports: Array[String]=[]
	for f in selected:
		ids.append(f.id)
		origins.append(layout.node(f.surface_id,f.pos))
		supports.append(f.surface_id)
	for i in selected.size():
		if not BattlePlacement.floor_open(s,origins[(i+1)%origins.size()],selected[i],Figure.BASE_RADIUS,1.6,true,null,-1,ids):
			return false
	for i in selected.size():
		var f:=selected[i]
		var n:=origins[(i+1)%origins.size()]
		f.pos=layout.point(n)
		f.elevation=layout.height(n)
		f.surface_id=layout.surface_id(n)
		f.disengaged.clear()
	for i in selected.size():
		var f:=selected[i]
		for other in s.figures:
			other.disengaged.erase(f.id)
		c.emit("layered_move",{"id":f.id,"path":PackedVector3Array([layout.world(origins[i]),Vector3(f.pos.x,f.elevation,f.pos.y)]),"surfaces":[supports[i],f.surface_id],"cost":0.0,"teleport":true})
		c._magic.terrain.trigger_landing(f)
	return true


static func convergence_nodes(s: GameState,f: Figure,moved: Array) -> Dictionary:
	var result: Dictionary={}
	var layout:=s.board.floor_geometry()
	for id: int in moved:
		var anchor:=s.figure(id)
		if anchor==null or not anchor.in_play() or anchor.ring_side!=f.ring_side:
			continue
		for n in BattlePlacement.nearby_floor(s,anchor.pos,anchor.elevation,1.5,anchor.surface_id,f):
			var at:=layout.point(n)
			if not result.has(at) and Contact.touching(anchor.pos,at) and anchor.pos.distance_to(at)>=Contact.OVERLAP:
				result[at]=n
	return result
