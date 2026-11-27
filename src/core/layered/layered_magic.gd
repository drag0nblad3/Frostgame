class_name LayeredMagic
extends RefCounted
## Teleport uses the existing casting roll and empowerment pipeline.
## No unsupported magical placement is offered on layered boards.


static func can_teleport(c: GameController,n: Vector3i) -> bool:
	var s := c.state
	var f := s.active()
	if s.board.floor_layout.is_empty() or f==null or not c.can_act() or not CasterLoadout.is_caster(f.def.role):
		return false
	if f.surface_id.begins_with("climb:") or ScenarioNull.muted(f):
		return false
	if not c._magic.available_spell(f,"teleport") or Contact.in_combat(s.figures,f) or f.spell_effects.has("blinding_light") or s.group.in_progress():
		return false
	var layout := s.board.floor_geometry()
	return can_teleport_with(c,n,layout,LayeredGrid.new(layout,f,s.figures))


## Reuses geometry for UI preview. Commit still runs complete action checks.
static func can_teleport_with(c: GameController,n: Vector3i,layout: FloorLayout,grid: LayeredGrid) -> bool:
	var s := c.state
	var f := s.active()
	if f==null or not layout.errors.is_empty() or not grid.open(n) or layout.surface_id(n).begins_with("climb:"):
		return false
	var to := layout.world(n)
	var from := Vector3(f.pos.x,f.elevation,f.pos.y)
	if ScenarioNull.muted(f) or ScenarioNull.field_at(s.board,layout.point(n)):
		return false
	if from.distance_to(to)<0.1:
		return false
	if not MovementContact.enemies_at(s.figures,f,layout.point(n),to.y,layout.surface_id(n)).is_empty():
		return false
	return LineOfSight.floor_point_visible(s.board,layout,f,to)


static func start_teleport(c: GameController,n: Vector3i) -> bool:
	if not can_teleport(c,n):
		return false
	var layout := c.state.board.floor_geometry()
	return c._magic._roll("teleport",c.state.active_id,null,false,-1,{"floor_destination":n,"surface_id":layout.surface_id(n)})


static func apply_teleport(c: GameController,f: Figure,effect: Dictionary) -> void:
	var layout := c.state.board.floor_geometry()
	var n: Vector3i = effect["floor_destination"]
	if not layout.standable(n) or layout.surface_id(n)!=effect["surface_id"]:
		return
	var start := Vector3(f.pos.x,f.elevation,f.pos.y)
	var old:=f.surface_id
	f.pos=layout.point(n)
	f.elevation=layout.height(n)
	f.surface_id=layout.surface_id(n)
	f.spell_effects.erase("bones_of_the_earth")
	f.magic_exhausted=true
	f.actions_left=0
	c.emit("layered_move",{"id":f.id,"path":PackedVector3Array([start,layout.world(n)]),"surfaces":[old,f.surface_id],"cost":0.0,"teleport":true})
	c._magic.illusions.after_move(f)
	ScenarioSites.end_move(c,f)
