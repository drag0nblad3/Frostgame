class_name MagicBot
extends RefCounted
## Initial spellcaster AI: heal allies or attempt a damaging spell.

static func play(c: GameController, f: Figure) -> bool:
	if f.def.role not in ["wizard", "apprentice"]:
		return false
	for id in ["heal", "control_demon", "control_undead", "control_construct", "control_animal", "mind_control", "elemental_bolt", "bone_dart", "steal_health"]:
		for t in c.state.figures:
			if (id == "heal" and (t.side != f.side or t.def.health - t.health < 3)) or (id != "heal" and t.side == f.side):
				continue
			if not c.start_cast(id, t.id):
				continue
			var p := c.state.pending_cast
			var needed := maxi(0, int(p["tn"]) - int(p["total"]))
			c.finish_cast(needed if needed <= mini(2, c.cast_max_empowerment()) and needed < f.health else 0)
			return true
	for id in ["raise_zombie", "summon_demon", "animate_skull"]:
		var points := c._magic.placement_points(id, true)
		if not points.is_empty() and c._magic.start_at(id, points[0]):
			var p := c.state.pending_cast
			var needed := maxi(0, int(p["tn"]) - int(p["total"]))
			c.finish_cast(needed if needed <= mini(2, c.cast_max_empowerment()) and needed < f.health else 0)
			return true
	return false
