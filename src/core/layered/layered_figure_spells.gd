class_name LayeredFigureSpells
extends RefCounted
## Compatibility queries. Figure-spell eligibility belongs to SpellAvailability.


static func visible(board: Board,f: Figure,t: Figure,limit: float) -> bool:
	if f.surface_id.is_empty() or t.surface_id.is_empty():
		return false
	return LineOfSight.within_centres(board,f,t,limit)


static func options(c: GameController) -> Dictionary:
	var out := {}
	var f := c.state.active()
	if f==null:
		return out
	for id in c._magic.available_spells(f):
		var ids: Array[int] = []
		for t in c.state.figures:
			if c.can_cast(id,t.id):
				ids.append(t.id)
		if not ids.is_empty():
			out[id]=ids
		if id=="enchant_weapon":
			var ammo: Array[int]=[]
			for t in c.state.figures:
				if c.can_cast(id,t.id,true):
					ammo.append(t.id)
			if not ammo.is_empty():
				out["enchant_ammo"]=ammo
	return out
