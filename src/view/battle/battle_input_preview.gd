class_name BattleInputPreview
extends RefCounted
## Legal-target highlights and the hint line for the current input mode.


static func preview(bi: BattleInput) -> void:
	bi.targets.clear()
	bi.tokens.clear()
	bi.nodes.clear()
	if bi.mode=="core_choice":
		var choice:=CoreScenarioChoice.pending(bi.c)
		var world:=PackedVector3Array()
		bi.floor_points.clear()
		bi.movement=null
		var hints: Dictionary={"genie":"Choose where the genie appears, within 2″ and closest to the finder.","worm":"Choose the worm’s emergence point adjacent to the selected treasure.","disc":"Choose a landing point entirely on the destination disc.","column":"Collect the revealed treasure for free, or leave it here?"}
		for p: Dictionary in choice.get("options",[]):
			if p.has("world") and BattleFloorInput.visible(bi,str(p.get("surface",""))):
				world.append(p["world"])
		bi.markers.show_world_points(world,Color(0.28,0.9,0.8),0.25)
		bi.hud.set_actions(bi.available,bi.mode,str(hints.get(choice.get("kind",""),"Choose a legal option.")))
		return
	var s := State.new()
	var f := bi.c.state.active()
	bi.hud.set_active_summary(f)
	bi.floor_points.clear()
	bi.movement=null
	if bi.mode in BattleMovePlan.MODES and f!=null:
		bi.movement=BattleSpace.movement(bi.c,bi.mode,bi.reach)
		if bi.is_layered():
			for n: Vector3i in bi.movement.cost:
				bi.floor_points[n]=bi.movement.world(n)
		else:
			for n: Vector2i in bi.movement.cost:
				bi.nodes.append(n)
				s.points.append(MoveGrid.to_pos(n))
		s.hint="Tap or drag within the marked area. Confirm before spending an action."
		if bi.mode=="exit":
			s.hint="Choose an exit, then confirm to retreat."
		elif bi.mode=="jump":
			s.hint="Choose a jump destination. Landing can cause falling damage."
		elif bi.mode in ["run_for_it","run_talisman"]:
			s.hint="Plan a run up to %d inches. Confirm to end activation."%(6 if bi.mode=="run_talisman" else 3)
		elif bi.mode=="gear_cape_move":
			s.hint="Plan an escape move. The cape is spent on confirmation."
	elif bi.is_layered() and BattleFloorInput.preview(bi,s):
		pass
	elif not BattleInputActionPreview.actions(bi,f,s):
		BattleInputReactionPreview.reactions(bi,f,s)
	if bi.is_layered():
		BattleFloorInput.draw_points(bi,s)
	else:
		var selected: Array[Vector2]=[]
		for t in bi.targets:
			if bi.mode=="group_select" and bi.group_selection.has(t.id):
				selected.append(t.pos)
			else:
				s.points.append(t.pos)
		bi.markers.show_points(s.points,s.color,s.radius)
		if not selected.is_empty():
			bi.markers.show_points(selected,Color(1.0,0.78,0.15),0.85,true)
	if not bi.c._magic.shatter.first.is_empty():
		s.hint = "Shatterstar: first attempt declared. Choose the second target before rolling. " + s.hint
	if f != null:
		if FuryRules.target(bi.c.state, f) != null:
			s.hint = "Fury: charge or fight the nearest eligible enemy. " + s.hint
		if HolyLantern.lit(f):
			s.hint="Lantern lit"+(" · shutter at turn end. " if f.used_gear.get(HolyLantern.CLOSE,false) else ". ")+s.hint
		if f.used_gear.get(RedKingDirection.ARMED,false):
			s.hint="Direction reroll armed. "+s.hint
		if f.used_gear.get(RedKingElemental.ARMED,false):
			s.hint="Full elemental absorption armed. "+s.hint
		if f.next_cast_gear != "":
			s.hint = "Armed: %s. " % f.next_cast_gear.trim_prefix("gear_").replace("_", " ").capitalize() + s.hint

	if bi.c.state.group.in_progress():
		s.hint = ("GROUP: Movement · " if bi.c.state.group.movement_pass() else "GROUP: Second action · ") + s.hint
	var action_info:=CombatHudInfo.action(bi,f)
	if not action_info.is_empty():
		s.hint=action_info+"\n"+s.hint
	if bi.mode in ["spell_target","spell_point","counter_select","treasure_spell","treasure_destination","leap_destination","swap_second","floor_teleport","floor_leap_target","floor_leap","floor_bridge","floor_bridge_end","floor_spell_point","floor_treasure_destination","floor_suggestion"] and bi.c.state.spell_catalog.has(bi.selected_spell):
		var info: Dictionary=bi.c.state.spell_catalog[bi.selected_spell]
		var tn:=int(bi.c.state.spellbooks.get(f.side,{}).get(bi.selected_spell,info["number"])) if f!=null else int(info["number"])
		s.hint="%s · TN %d — %s"%[info["name"],tn,s.hint]
	bi.hud.set_actions(bi.available,bi.mode,s.hint)



## What the current mode highlights and the hint shown with it.
class State:
	var world_points:=PackedVector3Array()
	var points: Array[Vector2] = []
	var color := Color(0.28, 0.9, 0.8)
	var radius := 0.17
	var hint := "Tap a highlighted figure to activate."
