class_name FloorDisplacement
extends RefCounted
## Forced movement samples the actual support along a horizontal ray. A
## ledge descent lands on the first lower surface, not the highest surface
## at the end of the push, and cannot cross solid volume.

static func trace(c: GameController,f: Figure,direction: Vector2,distance: float,stop_occupied: bool=false) -> Dictionary:
	var s:=c.state
	var layout:=s.board.floor_geometry()
	var start:=layout.node(f.surface_id,f.pos)
	if not layout.standable(start) or direction.is_zero_approx():
		return {}
	var path:=PackedVector3Array([layout.world(start)])
	var node:=start
	var safe:=start
	var safe_count:=1
	var collision:=false
	var void_at: Variant=null
	var blocked_at: Variant=null
	var origin:=f.pos
	var samples:=floori(distance/0.25)
	for i in range(1,samples+1):
		var at:=MoveGrid.to_pos(MovePlanner.node_at(origin+direction.normalized()*(i*0.25)))
		if at.distance_to(origin)>distance+0.001:
			continue
		if at.is_equal_approx(layout.point(node)):
			continue
		var from:=layout.world(node)
		if BattleBoundary.blocks_segment(s.board.boundaries,layout.point(node),at,"movement",f) or BattleBoundary.blocks_position(s.board.boundaries,at,f) or ScenarioNull.field_at(s.board,at):
			break
		if s.board.over_void(at,Figure.BASE_RADIUS):
			void_at=at
			break
		blocked_at=Vector3(at.x,from.y,at.y)
		var next: Variant=null
		var same:=layout.node(layout.surface_id(node),at)
		var support:=layout.surfaces[node.z]
		var continuous:=false
		if layout.standable(same) and not support.id.begins_with("climb:"):
			if support.profiles.is_empty():
				continuous=not is_equal_approx(support.level,support.end_level)
			else:
				var profile:=support.profile_at(layout.point(node))
				continuous=profile!=null and profile.ramp and profile==support.profile_at(at)
		if layout.standable(same) and (continuous or layout.height(same)<=from.y+0.5):
			next=same
		else:
			# First try adjoining support at the same height, then a fall.
			var best: Variant=null
			var top:=-INF
			for surface in layout.surfaces:
				if surface.id.begins_with("climb:"):
					continue
				var candidate:=layout.node(surface.id,at)
				if not layout.contains(candidate) or layout.height(candidate)>from.y+0.001:
					continue
				if layout.height(candidate)>top:
					best=candidate
					top=layout.height(candidate)
			if best!=null:
				next=best
		if next==null:
			collision=true
			break
		var to:=layout.world(next)
		var edge:=Vector3(to.x,from.y,to.z)
		var landing: bool=from.y-to.y>0.5 and not (next==same and continuous)
		var end:=edge if landing else to
		var clear:=true
		for step in range(1,5):
			if not layout.clearance(from.lerp(end,step/4.0),Figure.BASE_RADIUS,1.6):
				clear=false
				break
		if not clear:
			collision=true
			break
		if landing and not LayeredFall.clear_descent(layout,to,from.y):
			# The figure's base can temporarily overhang the edge while
			# still at deck height. Do not commit a landing through the
			# slab; trace horizontally until the base clears the lip.
			if layout.surfaces[node.z].rect.grow(Figure.BASE_RADIUS-0.001).has_point(at):
				continue
			collision=true
			break
		# A falling figure cannot pass through an occupied first landing.
		if (landing or stop_occupied) and not BattlePlacement.floor_open(s,next,f):
			break
		if landing:
			path.append(edge)
		path.append(to)
		else:
			path.append(to)
		blocked_at=null
		node=next
		if BattlePlacement.floor_open(s,node,f):
			safe=node
			safe_count=path.size()
		# Resolve a drop at the first landing, not on a later lower deck.
		if landing:
			break
	path.resize(safe_count)
	return {"node":safe,"path":path,"collision":collision,"void_at":void_at,"blocked_at":blocked_at}
