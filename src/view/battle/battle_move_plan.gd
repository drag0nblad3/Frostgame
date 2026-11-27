class_name BattleMovePlan
extends RefCounted
## UI-only tentative movement. A destination may identify a distinct floor.
## No rule actions, dice or events are executed before explicit commitment.
const MODES := ["move","exit","run_for_it","run_talisman","gear_cape_move","jump"]
var destination: Variant=null
var actor := -1


func choose(bi: BattleInput,at: Vector2) -> bool:
	return choose_node(bi,MovePlanner.node_at(at))


func choose_node(bi: BattleInput,n: Variant) -> bool:
	if bi.mode not in MODES or bi.movement==null or not bi.movement.cost.has(n):
		return false
	var f:=bi.c.state.active()
	if f==null:
		return false
	if destination==n and actor==f.id:
		return true
	var first:=destination==null
	destination=n
	actor=f.id
	var point:=bi.movement.world(n)
	bi.markers.show_world_plan(bi.movement.path(n))
	bi.move_preview_changed.emit(actor,point,true)
	var cost:=float(bi.movement.cost[n])
	var budget:=3.0 if bi.mode=="run_for_it" else (6.0 if bi.mode=="run_talisman" else MoveRules.allowance(f))
	var hint:="PREVIEW · %.1f″ of %.1f″ movement · %.1f″ remaining"%[cost,budget,maxf(0.0,budget-cost)]
	if n is Vector3i:
		hint+=" · %s · %.1f″ elevation"%[bi.movement.layout.surface_id(n).replace("_"," ").capitalize(),point.y]
	hint+="\nDrag or tap another marked position. Confirm to resolve movement and any reactions; Undo returns to your starting position."
	if bi.mode in ["run_for_it","run_talisman"]:
		hint+="\nRunning ends this activation."
	elif bi.mode=="gear_cape_move":
		hint+="\nThe cape is spent on commitment."
	elif bi.mode=="exit":
		hint+="\nConfirm to extract this figure."
	elif bi.mode=="jump":
		hint+="\nLanding may cause falling damage."
	if first:
		bi.available.assign(["move_confirm","move_undo"])
		bi.hud.set_actions(bi.available,bi.mode,hint)
	else:
		bi.hud.set_hint(hint)
	return true


func clear(bi: BattleInput) -> void:
	var previous:=actor
	var pending:=destination!=null
	destination=null
	actor=-1
	if pending:
		bi.move_preview_changed.emit(previous,Vector3.ZERO,false)
	bi.markers.clear_move_plan()


func confirm(bi: BattleInput) -> bool:
	var f:=bi.c.state.active()
	if destination==null or f==null or f.id!=actor:
		clear(bi)
		bi.refresh()
		return false
	var n: Variant=destination
	clear(bi)
	var ok:=bi.c.commit_movement(bi.mode,n)
	if not ok:
		bi.refresh()
	return ok


func can_begin_drag(bi: BattleInput,screen: Vector2) -> bool:
	if bi.mode not in MODES or bi.movement==null:
		return false
	var f:=bi.c.state.active()
	if f==null:
		return false
	var pos:=bi.movement.world(destination) if destination!=null else TableSpace.to_world(f.pos,f.elevation)
	if bi.camera.unproject_position(pos+Vector3.UP*0.65).distance_to(screen)<36.0:
		return true
	if bi.is_layered():
		return bi.floor_target_at(screen)!=null
	var hit: Variant=bi._surface_at(screen)
	return hit!=null and bi.movement.cost.has(MovePlanner.node_at(hit))
