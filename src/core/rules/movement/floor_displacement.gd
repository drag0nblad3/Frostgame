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


## A Push from above or below follows the actual 3D line of force.
## Resolve the last clear airborne point onto its first supporting floor.
## Horizontal Push and Blink keep the existing terrain-following trace.
static func trace_vertical(c: GameController,f: Figure,direction: Vector3,distance: float) -> Dictionary:
	var s:=c.state
	var layout:=s.board.floor_geometry()
	var start:=layout.node(f.surface_id,f.pos)
	if not layout.standable(start) or direction.is_zero_approx() or distance<=0.0:
		return {}
	var origin:=layout.world(start)
	var ray:=direction.normalized()
	var path:=PackedVector3Array([origin])
	var collision:=false
	var blocked_at: Variant=null
	var void_at: Variant=null
	var grid:=LayeredGrid.new(layout,f,s.figures)
	var samples:=maxi(1,ceili(distance*10.0))
	for i in range(1,samples+1):
		var p:=origin+ray*(distance*float(i)/samples)
		var at:=Vector2(p.x,p.z)
		var last:=path[-1]
		var previous:=Vector2(last.x,last.z)
		if not s.board.contains(at,Figure.BASE_RADIUS):
			collision=true
			blocked_at=p
			break
		if BattleBoundary.blocks_segment(s.board.boundaries,previous,at,"movement",f) or BattleBoundary.blocks_position(s.board.boundaries,at,f) or ScenarioNull.field_at(s.board,at):
			break
		if s.board.over_void(at,Figure.BASE_RADIUS):
			void_at=at
			break
		if ray.y<0.0:
			var contact: Variant=_crossed_support(layout,p,last)
			if contact!=null:
				if BattlePlacement.floor_open(s,contact,f) and LayeredFall.clear_descent(layout,layout.world(contact),last.y):
					path.append(layout.world(contact))
					return {"node":contact,"path":path,"collision":false,"void_at":null,"blocked_at":null,"fall_distance":maxf(0.0,origin.y-layout.height(contact))}
				collision=true
				blocked_at=p
				break
		if not layout.clearance(p,Figure.BASE_RADIUS,1.6) or TerrainMagic.ward_blocks(s.board,f,at,p.y):
			collision=true
			blocked_at=p
			break
		path.append(p)
	# If the final air position is blocked below or occupied, find the last
	# point on the same ray with a legal landing. Never pass through a deck.
	for i in range(path.size()-1,-1,-1):
		var p:=path[i]
		var at:=MoveGrid.to_pos(MovePlanner.node_at(Vector2(p.x,p.z)))
		var edge:=Vector3(at.x,p.y,at.y)
		if not _clear_air_segment(s,f,layout,p,edge):
			continue
		var landing: Variant=LayeredFall.landing(layout,grid,at,p.y+0.002)
		if landing==null or not BattlePlacement.floor_open(s,landing,f):
			continue
		var dest:=layout.world(landing)
		if not LayeredFall.clear_descent(layout,dest,maxf(p.y,dest.y)):
			continue
		path.resize(i+1)
		if not path[-1].is_equal_approx(edge):
			path.append(edge)
		if not path[-1].is_equal_approx(dest):
			path.append(dest)
		return {"node":landing,"path":path,"collision":collision,"void_at":void_at,"blocked_at":blocked_at,"fall_distance":maxf(0.0,maxf(origin.y,p.y)-dest.y)}
	return {"node":start,"path":PackedVector3Array([origin]),"collision":collision,"void_at":void_at,"blocked_at":blocked_at,"fall_distance":0.0}


static func _crossed_support(layout: FloorLayout,p: Vector3,last: Vector3) -> Variant:
	var at:=Vector2(p.x,p.z)
	var highest:=-INF
	var best: Variant=null
	for surface in layout.surfaces:
		if surface.id.begins_with("climb:") or not surface.contains(at,Figure.BASE_RADIUS):
			continue
		var n:=layout.node(surface.id,at)
		if not layout.contains(n):
			continue
		var h:=layout.height(n)
		if h>=p.y-0.001 and h<=last.y+0.001 and h>highest:
			best=n
			highest=h
	return best


static func _clear_air_segment(s: GameState,f: Figure,layout: FloorLayout,a: Vector3,b: Vector3) -> bool:
	var steps:=maxi(1,ceili(a.distance_to(b)*10.0))
	for i in range(1,steps+1):
		var p:=a.lerp(b,float(i)/steps)
		var at:=Vector2(p.x,p.z)
		if s.board.over_void(at,Figure.BASE_RADIUS) or not layout.clearance(p,Figure.BASE_RADIUS,1.6) or TerrainMagic.ward_blocks(s.board,f,at,p.y):
			return false
	return not BattleBoundary.blocks_segment(s.board.boundaries,Vector2(a.x,a.z),Vector2(b.x,b.z),"movement",f)
