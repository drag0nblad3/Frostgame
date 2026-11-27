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
	return c.state.active()!=null and BattlePlacement.teleport_legal(c.state,c.state.active(),n)


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
	c._magic.movement.move_floor(f,n,true,false,"teleport")
