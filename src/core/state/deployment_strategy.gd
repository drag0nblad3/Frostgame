class_name DeploymentStrategy
extends RefCounted
## Heuristics for automatic deployment; opponents not yet placed are ignored.


static func best(s: GameState,f: Figure,points: Array[Dictionary],zone: int,placed: Dictionary) -> Dictionary:
	var best_point: Dictionary={}
	var score:=INF
	var center:=s.board.size*0.5
	var target:=center
	var best_goal:=INF
	var anchor:=DeploymentRules.edge_point(s.board.size,zone)
	if DeploymentRules.kind(s)=="corner":
		anchor=Vector2(0 if zone==0 else s.board.size.x,0)
	elif DeploymentRules.kind(s)=="ring":
		anchor=Vector2(s.board.size.x*0.25 if f.side==0 else s.board.size.x*0.75,center.y)
	for t in s.treasures:
		if not t.on_ground() or t.ring_side!=f.ring_side:
			continue
		var distance:=anchor.distance_to(t.pos)
		if distance<best_goal:
			best_goal=distance
			target=t.pos
	var central: TreasureToken=null
	for t in s.treasures:
		if (t.central or (t.id==0 and StandardTreasurePlacement.enabled(s))) and t.on_ground():
			central=t
			break
	var caster: Figure=null
	for other in s.figures:
		if other.side==f.side and placed.has(other.id) and other.def.role=="wizard":
			caster=other
			break
	var ranged:=f.def.ranged_weapon()!=null
	for p in points:
		var at: Vector2=p["at"]
		var h:=float(p["height"])
		var value:=at.distance_to(target)*0.8
		if DeploymentRules.kind(s)=="ring" and f.def.role=="wizard":
			value=at.distance_to(anchor)*2.0
		if ranged:
			value=at.distance_to(target)*0.45-h*0.75
		if caster!=null:
			var d:=at.distance_to(caster.pos)
			value+=maxf(0.0,d-3.0)*1.8+absf(d-1.8)*0.26
		for piece in s.board.pieces:
			if piece.kind.cover!=TerrainKind.Cover.NONE and Geom.point_rect_distance(at,piece.rect)<=1.8:
				value-=0.65 if ranged or f.def.role!="soldier" else 0.3
		for other in s.figures:
			if not placed.has(other.id) or other.side!=f.side or other==f:
				continue
			# Avoid a single packed line; keep enough room to move.
			value+=maxf(0.0,1.7-at.distance_to(other.pos))*0.5
		# Remaining sight penalties are nonnegative. A point whose lower
		# bound already loses cannot beat the current best candidate.
		if value>=score:
			continue
		# Prefer screened starting positions, but never forbid a legal square.
		if DeploymentRules.kind(s) in ["edge","door"]:
			var exposed:=false
			for other in s.figures:
				if other.side>=0 and other.side!=f.side and placed.has(other.id) and LineOfSight.check_from_world(s.board,f,Vector3(at.x,h,at.y),other).clear:
					exposed=true
					break
			if exposed:
				value+=12.0
			if value>=score:
				continue
			if central!=null:
				var visible:=LineOfSight.check(s.board,at,central.pos,f).clear if s.board.floor_layout.is_empty() else LineOfSight.floor_ray(s.board,s.board.floor_geometry(),Vector3(at.x,h+1.5,at.y),StandardTreasurePlacement.world(s,central)+Vector3.UP*0.02,f)
				if visible:
					value+=16.0
		if value<score:
			score=value
			best_point=p
	return best_point
