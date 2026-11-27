class_name LayeredJump
extends RefCounted
## An authored gap, with a straight run-up of at least the jump distance.
## Run-up and jump are both paid from the same movement action.


static func plans(c: GameController) -> Dictionary:
	var out := {}
	if not LayeredMovement.eligible(c):
		return out
	var s := c.state
	var f := s.active()
	var layout := FloorLayout.from_dict(s.board.floor_layout)
	if not layout.errors.is_empty():
		return out
	var grid := LayeredGrid.new(layout,f,s.figures)
	var start := layout.node(f.surface_id,f.pos)
	if not grid.open(start):
		return out
	for entry: Dictionary in s.board.floor_layout.get("jumps",[]):
		var from: Array = entry.get("from",[])
		var to: Array = entry.get("to",[])
		if from.size()!=3 or to.size()!=3:
			continue
		var takeoff := layout.node(str(from[0]),Vector2(from[1],from[2]))
		var target := layout.node(str(to[0]),Vector2(to[1],to[2]))
		if not grid.open(takeoff) or not grid.open(target) or start.z!=takeoff.z:
			continue
		if layout.height(target)>layout.height(takeoff)+0.001:
			continue
		var delta := layout.point(target)-layout.point(takeoff)
		var distance := delta.length()
		if distance<=0.001 or distance>4.0:
			continue
		var run := layout.point(takeoff)-layout.point(start)
		if run.length()+0.001<distance or run.normalized().dot(delta.normalized())<0.999:
			continue
		var path := PackedVector3Array()
		var cost := 0.0
		var valid := true
		var steps := maxi(1,ceili(run.length()/0.1))
		for i in range(steps+1):
			var p := layout.point(start).lerp(layout.point(takeoff),float(i)/steps)
			var h := layout.surfaces[start.z].height_at(p)
			if not layout.surfaces[start.z].contains(p,Figure.BASE_RADIUS) or not layout.clearance(Vector3(p.x,h,p.y),Figure.BASE_RADIUS,1.6) or not is_equal_approx(h,layout.height(start)):
				valid=false
				break
			for other in grid.others:
				if absf(other.elevation-h)<0.5 and (other.pos.distance_to(p)<Contact.OVERLAP or (other.side!=f.side and Contact.touching(other.pos,p))):
					valid=false
					break
			if not valid:
				break
		cost=run.length()*layout.surfaces[start.z].rough+distance
		if not valid or cost>MoveRules.allowance(f)+0.001:
			continue
		var a := layout.world(takeoff)
		var b := layout.world(target)
		path.append(layout.world(start))
		path.append(a)
		steps=maxi(2,ceili(distance/0.1))
		for i in range(1,steps):
			var t := float(i)/steps
			# A modest arc; descending figures remain high until reaching the edge.
			var p := a.lerp(Vector3(b.x,a.y,b.z),t)+Vector3.UP*(2.0*t*(1.0-t))
			if not layout.clearance(p,Figure.BASE_RADIUS,1.6):
				valid=false
				break
			path.append(p)
		if not valid or not LayeredFall.clear_descent(layout,b,a.y):
			continue
		path.append(Vector3(b.x,a.y,b.z))
		path.append(b)
		out[target]={"path":path,"cost":cost,"fall":a.y-b.y}
	return out


static func move(c: GameController,n: Vector3i) -> bool:
	var options := plans(c)
	if not options.has(n):
		return false
	var f := c.state.active()
	var engaged:=Contact.in_combat(c.state.figures,f)
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var plan: Dictionary = options[n]
	var old := f.surface_id
	f.pos=layout.point(n)
	f.elevation=layout.height(n)
	f.surface_id=layout.surface_id(n)
	c.spend_move(f)
	c.emit("layered_move",{"id":f.id,"path":plan["path"],"surfaces":[old,f.surface_id],"cost":plan["cost"],"jump":true})
	LayeredFall.apply(c,f,float(plan["fall"]),f)
	c.finish_movement(f,engaged,f.in_play())
	return true
