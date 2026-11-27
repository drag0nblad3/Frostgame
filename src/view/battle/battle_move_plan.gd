class_name BattleMovePlan
extends RefCounted
## UI-only tentative movement. No rules action, roll, event, or state mutation
## until the explicit confirmation uses the original controller movement API.
const MODES := ["move","exit","run_for_it","run_talisman","gear_cape_move"]
var destination: Variant = null
var actor := -1


func choose(bi: BattleInput,at: Vector2) -> bool:
	if bi.mode not in MODES or bi.reach==null:
		return false
	var f := bi.c.state.active()
	if f==null:
		return false
	var n := MovePlanner.node_at(at)
	if not bi.nodes.has(n) or not bi.reach.can_reach(n):
		return false
	if destination==n and actor==f.id:
		return true
	var first := destination==null
	destination=n
	actor=f.id
	var point := MoveGrid.to_pos(n)
	bi.markers.show_move_plan(bi.reach.path_to(n))
	bi.move_preview_changed.emit(actor,point,true)
	var cost := float(bi.reach.cost[n])
	var budget := 3.0 if bi.mode=="run_for_it" else (6.0 if bi.mode=="run_talisman" else MoveRules.allowance(f))
	var hint := "PREVIEW · %.1f″ of %.1f″ movement · %.1f″ remaining\nDrag or tap another marked position. Confirm to resolve movement and any reactions; Undo returns to your starting position."%[cost,budget,maxf(0.0,budget-cost)]
	if bi.mode in ["run_for_it","run_talisman"]:
		hint+="\nRunning ends this activation."
	elif bi.mode=="gear_cape_move":
		hint+="\nThe cape is spent on commitment."
	elif bi.mode=="exit":
		hint+="\nConfirm to extract this figure."
	if first:
		bi.available.assign(["move_confirm","move_undo"])
		bi.hud.set_actions(bi.available,bi.mode,hint)
	else:
		bi.hud.set_hint(hint)
	return true


func clear(bi: BattleInput) -> void:
	if destination!=null:
		bi.move_preview_changed.emit(actor,Vector2.ZERO,false)
	destination=null
	actor=-1
	bi.markers.clear_move_plan()


func confirm(bi: BattleInput) -> bool:
	var f := bi.c.state.active()
	if destination==null or f==null or f.id!=actor:
		clear(bi)
		bi.refresh()
		return false
	var n: Vector2i=destination
	clear(bi)
	# Revalidate via the controller, which owns all movement reactions.
	var ok := false
	match bi.mode:
		"exit": ok=bi.c.exit_table(n)
		"run_for_it","run_talisman": ok=RunForIt.apply(bi.c,n,bi.mode=="run_talisman")
		"gear_cape_move": ok=bi.c.move_to(n,true)
		_: ok=bi.c.move_to(n)
	if not ok:
		bi.refresh()
	return ok


func can_begin_drag(bi: BattleInput,screen: Vector2) -> bool:
	if bi.mode not in MODES or bi.reach==null:
		return false
	var f := bi.c.state.active()
	if f==null:
		return false
	# The miniature itself can be grabbed even when its centre is off-grid.
	var pos := MoveGrid.to_pos(destination) if destination!=null else f.pos
	if bi.camera.unproject_position(TableSpace.to_world(pos,bi.c.state.board.height_at(pos)+0.65)).distance_to(screen)<36.0:
		return true
	var hit: Variant=bi._surface_at(screen)
	return hit!=null and bi.nodes.has(MovePlanner.node_at(hit))
