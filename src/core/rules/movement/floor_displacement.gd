class_name FloorDisplacement
extends RefCounted
## Forced movement samples the actual support along a horizontal ray. A
## ledge descent lands on the first lower surface, not the highest surface
## at the end of the push, and cannot cross solid volume.

static func trace(c: GameController,f: Figure,direction: Vector2,distance: float) -> Dictionary:
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
		var next: Variant=null
		var same:=layout.node(layout.surface_id(node),at)
		if layout.standable(same) and layout.height(same)<=from.y+0.5:
			next=same
		else:
			# First try adjoining support at the same height, then a fall.
			var best: Variant=null
			var top:=-INF
			for candidate in layout.nodes_at(at):
				if layout.surface_id(candidate).begins_with("climb:") or layout.height(candidate)>from.y+0.001:
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
		var landing:=from.y-to.y>0.5
		var end:=edge if landing else to
		var clear:=true
		for step in range(1,5):
			if not layout.clearance(from.lerp(end,step/4.0),Figure.BASE_RADIUS,1.6):
				clear=false
				break
		if not clear or (landing and not LayeredFall.clear_descent(layout,to,from.y)):
			collision=true
			break
		# A falling figure cannot pass through an occupied first landing.
		if landing and not BattlePlacement.floor_open(s,next,f):
			break
		if landing:
			path.append(edge)
		path.append(to)
		node=next
		if BattlePlacement.floor_open(s,node,f):
			safe=node
			safe_count=path.size()
		# Resolve a drop at the first landing, not on a later lower deck.
		if landing:
			break
	path.resize(safe_count)
	return {"node":safe,"path":path,"collision":collision}
