class_name BattleMovePlan
extends RefCounted
## UI-only tentative movement. A destination may identify a distinct floor.
## No rule actions, dice or events are executed before explicit commitment.
const MODES := ["move","exit","run_for_it","run_talisman","gear_cape_move","jump","drop_down"]
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
	draw(bi)
	bi.move_preview_changed.emit(actor,point,true)
	var cost:=float(bi.movement.cost[n])
	var budget:=3.0 if bi.mode=="run_for_it" else (6.0 if bi.mode=="run_talisman" else MoveRules.allowance(f))
	var hint:="PREVIEW · %.1f″ / %.1f″ movement · %.1f″ remaining"%[cost,budget,maxf(0.0,budget-cost)]
	if n is Vector3i:
		var support:=bi.movement.layout.surface_id(n)
		hint+="\n%s · %.1f″ elevation (%+.1f″)"%["Hanging on wall" if support.begins_with("climb:") else support.replace("_"," ").capitalize(),point.y,point.y-f.elevation]
		if support.begins_with("climb:"):
			hint+="\nFinish the climb on a later movement action."
	hint+="\nDrag or tap another marked position. Confirm to resolve movement and any reactions; Undo returns to your starting position."
	if bi.mode in ["run_for_it","run_talisman"]:
		hint+="\nRunning ends this activation."
	elif bi.mode=="gear_cape_move":
		hint+="\nThe cape is spent on commitment."
	elif bi.mode=="exit":
		hint+="\nConfirm to extract this figure."
	if bi.movement.jumps.has(n):
		var risk:=aerial_risk(bi.c.state,f,bi.movement.jumps[n])
		if float(risk["descent"])>0.0:
			hint+="\nDescent %.1f″ · up to %d fall damage"%[risk["descent"],risk["damage"]]
		if int(risk["legs"])>1:
			hint+=" · %d aerial legs"%risk["legs"]
		if risk["end"]:
			hint+=" · Ends activation"
		if int(risk["damage"])>=f.health:
			hint+="\nWARNING: potentially fatal fall."
		elif int(risk["damage"])>0:
			hint+="\nDamage or reactions may interrupt the remaining route."
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


## Presentation reads the same fall rule as actual resolution; chained legs
## are conditional, so display the sum as a possible maximum, not a promise.
static func aerial_risk(s: GameState,f: Figure,plan: Dictionary) -> Dictionary:
	var descent:=float(plan.get("fall",0.0))
	var risk: Dictionary={"descent":descent,"damage":LayeredFall.damage(s,f,descent),"legs":1,"end":bool(plan.get("end_activation",false))}
	if plan.has("next"):
		var following:=aerial_risk(s,f,plan["next"])
		risk["descent"]+=following["descent"]
		risk["damage"]+=following["damage"]
		risk["legs"]+=following["legs"]
		risk["end"]=risk["end"] or following["end"]
	return risk


func draw(bi: BattleInput) -> void:
	if destination==null or bi.movement==null:
		return
	var f:=bi.c.state.active()
	var danger:=0
	if f!=null and bi.movement.jumps.has(destination):
		danger=int(aerial_risk(bi.c.state,f,bi.movement.jumps[destination])["damage"])
	bi.markers.show_world_plan(bi.movement.path(destination),danger>0)
