class_name LayeredLeap
extends RefCounted
## Friendly target, explicit landing floor, straight or arcing trajectory.
## The target exhausts its remaining actions; use normal spell resolution.


static func eligible(c: GameController,t: Figure) -> bool:
	var s := c.state
	var f := s.active()
	if s.board.floor_layout.is_empty() or f==null or t==null or not t.in_play() or t.side!=f.side:
		return false
	if ScenarioNull.muted(f) or ScenarioNull.muted(t):
		return false
	if not c.can_act() or not CasterLoadout.is_caster(f.def.role) or not c._magic.available_spell(f,"leap"):
		return false
	if Contact.in_combat(s.figures,f) or f.spell_effects.has("blinding_light") or s.group.in_progress():
		return false
	if t.spell_effects.has("bones_of_the_earth") or t.spell_effects.has("petrify") or t.surface_id.begins_with("climb:"):
		return false
	return f==t or LineOfSight.check_figures(s.board,f,t).clear


static func path(c: GameController,t: Figure,n: Vector3i,layout: FloorLayout,grid: LayeredGrid) -> PackedVector3Array:
	var empty := PackedVector3Array()
	if not grid.open(n) or layout.surface_id(n).begins_with("climb:") or ScenarioNull.field_at(c.state.board,layout.point(n)):
		return empty
	var a := Vector3(t.pos.x,t.elevation,t.pos.y)
	var b := layout.world(n)
	var limit := 5.0 if t.treasure_id>=0 else 10.0
	if a.distance_to(b)<0.1 or a.distance_to(b)>limit+0.001:
		return empty
	for enemy in c.state.figures:
		if enemy.in_play() and enemy.side!=t.side and absf(enemy.elevation-b.y)<0.5 and Contact.touching(enemy.pos,layout.point(n)):
			return empty
	# A straight trajectory is preferred. Test several bounded vertical arcs
	# without allowing horizontal curves around obstacles.
	for rise: float in [0.0,1.0,2.0,3.0]:
		var points := PackedVector3Array([a])
		var steps := maxi(2,ceili((a.distance_to(b)+rise*2.0)/0.1))
		var length := 0.0
		var clear := true
		for i in range(1,steps+1):
			var ratio := float(i)/steps
			var p := a.lerp(b,ratio)+Vector3.UP*(4.0*rise*ratio*(1.0-ratio))
			if ScenarioNull.field_at(c.state.board,Vector2(p.x,p.z)) or not layout.clearance(p,Figure.BASE_RADIUS,1.6):
				clear=false
				break
			length+=points[points.size()-1].distance_to(p)
			points.append(p)
		if clear and length<=limit+0.001:
			return points
	return empty


static func start(c: GameController,t: Figure,n: Vector3i) -> bool:
	if not eligible(c,t):
		return false
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var points := path(c,t,n,layout,LayeredGrid.new(layout,t,c.state.figures))
	if points.is_empty():
		return false
	return c._magic._roll("leap",t.id,null,false,-1,{"floor_destination":n,"surface_id":layout.surface_id(n),"leap_path":points})


static func apply(c: GameController,t: Figure,effect: Dictionary) -> void:
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var n: Vector3i = effect["floor_destination"]
	if not layout.standable(n) or layout.surface_id(n)!=effect["surface_id"]:
		return
	var old := t.surface_id
	t.pos=layout.point(n)
	t.elevation=layout.height(n)
	t.surface_id=layout.surface_id(n)
	t.magic_exhausted=true
	t.actions_left=0
	c.emit("layered_move",{"id":t.id,"path":effect["leap_path"],"surfaces":[old,t.surface_id],"cost":0.0,"leap":true})
