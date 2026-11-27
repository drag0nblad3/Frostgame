class_name BattleInputPreview
extends RefCounted
## Legal-target highlights and the hint line for the current input mode.


static func preview(bi: BattleInput) -> void:
	bi.targets.clear()
	bi.tokens.clear()
	bi.nodes.clear()
	var s := State.new()
	var f := bi.c.state.active()
	bi.hud.set_active_summary(f)
	if not BattleInputActionPreview.actions(bi, f, s):
		BattleInputReactionPreview.reactions(bi, f, s)
	var selected: Array[Vector2] = []
	for t in bi.targets:
		if bi.mode == "group_select" and bi.group_selection.has(t.id):
			selected.append(t.pos)
		else:
			s.points.append(t.pos)
	bi.markers.show_points(s.points, s.color, s.radius)
	if not selected.is_empty():
		bi.markers.show_points(selected, Color(1.0, 0.78, 0.15), 0.85, true)
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
	bi.hud.set_actions(bi.available, bi.mode, s.hint)



## What the current mode highlights and the hint shown with it.
class State:
	var points: Array[Vector2] = []
	var color := Color(0.28, 0.9, 0.8)
	var radius := 0.17
	var hint := "Tap a highlighted figure to activate."
