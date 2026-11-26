class_name MagicBot
extends RefCounted
## Initial spellcaster AI: heal allies or attempt a damaging spell.

static func play(c: GameController, f: Figure) -> bool:
	if f.def.role not in ["wizard", "apprentice"]:
		return false
	for id in ["heal", "elemental_bolt", "bone_dart", "steal_health"]:
		for t in c.state.figures:
			if (id == "heal" and (t.side != f.side or t.def.health - t.health < 3)) or (id != "heal" and t.side == f.side):
				continue
			if not c.start_cast(id, t.id):
				continue
			var p := c.state.pending_cast
			var needed := maxi(0, int(p["tn"]) - int(p["total"]))
			c.finish_cast(needed if needed <= mini(2, c.cast_max_empowerment()) and needed < f.health else 0)
			return true
	return false
