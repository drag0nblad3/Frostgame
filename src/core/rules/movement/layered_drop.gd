class_name LayeredDrop
extends RefCounted
## Explicit voluntary fall (core p.50), from a current ledge or hanging
## position. Never add damaging descents to normal safe movement previews.

static func plans(c: GameController) -> Dictionary:
	var out: Dictionary={}
	if not LayeredMovement.eligible(c):
		return out
	var s:=c.state
	var f:=s.active()
	if FuryRules.target(s,f)!=null or PlaneWalk.uses_direct(f):
		return out
	var layout:=s.board.floor_geometry()
	var start:=layout.node(f.surface_id,f.pos)
	if not layout.standable(start):
		return out
	var support:=layout.surfaces[start.z]
	# Ordinary flat ground cannot drop; a profiled street may border a ditch.
	if support.id=="street" and support.profiles.is_empty() and is_equal_approx(support.level,support.end_level):
		return out
	var grid:=LayeredGrid.new(layout,f,s.figures)
	var a:=layout.world(start)
	var offsets: Array[Vector2i]=[Vector2i.ZERO]
	offsets.append_array(MoveGrid.NEIGHBORS)
	for d in MoveGrid.NEIGHBORS:
		if d.x==0 or d.y==0:
			offsets.append(d*2)
	for d in offsets:
		var at:=layout.point(start+Vector3i(d.x,d.y,0))
		var same:=layout.node(support.id,at)
		if not support.id.begins_with("climb:") and layout.standable(same) and layout.height(same)>=a.y-0.5:
			continue
		if s.board.over_void(at,Figure.BASE_RADIUS):
			continue
		var n: Variant=LayeredFall.landing(layout,grid,at,a.y)
		if n==null:
			continue
		var b:=layout.world(n)
		var drop:=a.y-b.y
		if drop<=0.5:
			continue
		# A continuous ramp is movement, not a voluntary fall.
		if n.z==start.z:
			var profile:=support.profile_at(f.pos)
			if profile!=null and profile.ramp and profile==support.profile_at(at):
				continue
			if support.profiles.is_empty() and not is_equal_approx(support.level,support.end_level):
				continue
		var edge:=Vector3(b.x,a.y,b.z)
		if not grid.segment_allowed(a,edge):
			continue
		var clear:=true
		for i in range(1,5):
			if not layout.clearance(a.lerp(edge,float(i)/4.0),Figure.BASE_RADIUS,1.6):
				clear=false
				break
		if not clear:
			continue
		var cost:=a.distance_to(edge)+drop+(3.0 if s.board.low_gravity else 0.0)
		var long_fall:=drop+(3.0 if s.board.low_gravity else 0.0)>float(f.effective_move())
		if cost>MoveRules.allowance(f)+0.001 and not (long_fall and f.moves_taken==0):
			continue
		out[n]={"path":PackedVector3Array([a,edge,b]),"cost":cost,"fall":drop,"end_activation":long_fall}
	return out


static func move(c: GameController,n: Vector3i) -> bool:
	var options:=plans(c)
	if not options.has(n):
		return false
	var f:=c.state.active()
	var layout:=c.state.board.floor_geometry()
	var plan: Dictionary=options[n]
	var targets:=MovementContact.enemies_at(c.state.figures,f,layout.point(n),layout.height(n),layout.surface_id(n))
	c._magic.beauty.authorize(f,targets,_land.bind(c,f,n,plan))
	return true


static func _land(c: GameController,f: Figure,n: Vector3i,plan: Dictionary) -> void:
	if not f.in_play() or c.state.active()!=f or not RedKingHill.before_move(c,f):
		return
	var layout:=c.state.board.floor_geometry()
	var old:=f.surface_id
	f.pos=layout.point(n)
	f.elevation=layout.height(n)
	f.surface_id=layout.surface_id(n)
	c.spend_move(f)
	c.emit("layered_move",{"id":f.id,"path":plan["path"],"surfaces":[old,f.surface_id,f.surface_id],"cost":plan["cost"],"fall":true})
	LayeredFall.apply(c,f,float(plan["fall"]),f)
	if f.in_play():
		c._magic.terrain.trigger_landing(f)
	c.finish_movement(f,false,f.in_play())
	if bool(plan["end_activation"]) and f.in_play():
		f.actions_left=0
		if c.can_end_activation():
			c.end_activation()
