class_name LayeredMagic
extends RefCounted
## Teleport uses the existing casting roll and empowerment pipeline.
## No unsupported magical placement is offered on layered boards.


static func can_teleport(c: GameController,n: Vector3i) -> bool:
	var s := c.state
	var f := s.active()
	if s.board.floor_layout.is_empty() or f==null or not c.can_act() or not CasterLoadout.is_caster(f.def.role):
		return false
	if not c._magic.available_spell(f,"teleport") or Contact.in_combat(s.figures,f) or f.spell_effects.has("blinding_light") or s.group.in_progress():
		return false
	var layout := FloorLayout.from_dict(s.board.floor_layout)
	return can_teleport_with(c,n,layout,LayeredGrid.new(layout,f,s.figures))


## Reuses geometry for UI preview. Commit still runs complete action checks.
static func can_teleport_with(c: GameController,n: Vector3i,layout: FloorLayout,grid: LayeredGrid) -> bool:
	var s := c.state
	var f := s.active()
	if f==null or not layout.errors.is_empty() or not grid.open(n):
		return false
	var to := layout.world(n)
	var from := Vector3(f.pos.x,f.elevation,f.pos.y)
	if from.distance_to(to)<0.1:
		return false
	for t in s.figures:
		if t.in_play() and t.side!=f.side and absf(t.elevation-to.y)<0.5 and Contact.touching(t.pos,layout.point(n)):
			return false
	return LayeredSight.clear(layout,from+Vector3.UP*1.5,to+Vector3.UP*0.02)


static func start_teleport(c: GameController,n: Vector3i) -> bool:
	if not can_teleport(c,n):
		return false
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	return c._magic._roll("teleport",c.state.active_id,null,false,-1,{"floor_destination":n,"surface_id":layout.surface_id(n)})


static func apply_teleport(c: GameController,f: Figure,effect: Dictionary) -> void:
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var n: Vector3i = effect["floor_destination"]
	if not layout.standable(n) or layout.surface_id(n)!=effect["surface_id"]:
		return
	var start := Vector3(f.pos.x,f.elevation,f.pos.y)
	f.pos=layout.point(n)
	f.elevation=layout.height(n)
	f.surface_id=layout.surface_id(n)
	f.spell_effects.erase("bones_of_the_earth")
	f.magic_exhausted=true
	f.actions_left=0
	c.emit("layered_move",{"id":f.id,"path":PackedVector3Array([start,layout.world(n)]),"surfaces":[f.surface_id],"cost":0.0,"teleport":true})
