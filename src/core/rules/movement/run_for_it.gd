class_name RunForIt
extends RefCounted

const TALISMAN := "gear_rk_talisman_of_speed"


static func ready(c: GameController,boost: bool=false) -> bool:
	var f := c.state.active()
	return f!=null and c.can_move() and f.side>=0 and not c.state.group.in_progress() and f.moves_taken==0 and not f.acted and f.non_moves==0 and not f.used_stored_action and f.actions_left==f.action_limit() and c.state.push_winner<0 and FuryRules.target(c.state,f)==null and not f.spell_effects.has("plane_walk") and not f.spell_effects.has("potion_burrowing") and (not boost or ActiveGear.ready(f,TALISMAN))


static func reach(c: GameController,boost: bool=false) -> MoveReach:
	if not ready(c,boost) or not c.state.board.floor_layout.is_empty():
		return MoveReach.new()
	var f := c.state.active()
	var grid := MoveGrid.new(c.state.board,f,c.state.figures)
	grid.running=true
	return MovePlanner.straight_reach(grid,f.pos,6.0 if boost else 3.0) if c.state.board.low_gravity else MovePlanner.reach(grid,f.pos,6.0 if boost else 3.0)


static func apply(c: GameController,node: Vector2i,boost: bool=false) -> bool:
	var r := reach(c,boost)
	if not r.can_reach(node) or float(r.cost[node])<=0.001:
		return false
	var f := c.state.active()
	if boost and not ActiveGear.spend(f,TALISMAN):
		return false
	if RedKingHill.before_move(c,f):
		c._apply_move(f,r.path_to(node),float(r.cost[node]),{})
	finish(c,f,boost)
	return true


static func finish(c: GameController,f: Figure,boost: bool) -> void:
	f.actions_left=0
	c.emit("run_for_it",{"id":f.id,"boost":boost})
	c.end_activation()
