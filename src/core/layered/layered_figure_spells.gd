class_name LayeredFigureSpells
extends RefCounted
## Explicitly migrated figure-only effects. No implicit fallback to flat placement.

const SUPPORTED := ["heal","elemental_shield","fleet_feet","strength","shield","enchant_weapon","enchant_armour","elemental_hammer","combat_awareness","glow","slow","curse","furious_quill","blinding_light","elemental_bolt","bone_dart","poison_dart"]


static func visible(board: Board,f: Figure,t: Figure,limit: float) -> bool:
	if f.surface_id.is_empty() or t.surface_id.is_empty():
		return false
	var a := Vector3(f.pos.x,f.elevation,f.pos.y)
	var b := Vector3(t.pos.x,t.elevation,t.pos.y)
	return a.distance_to(b)<=limit+0.001 and LineOfSight.check_figures(board,f,t).clear


static func options(c: GameController) -> Dictionary:
	var out := {}
	var f := c.state.active()
	if f==null:
		return out
	for id in c._magic.available_spells(f):
		if not SUPPORTED.has(id):
			continue
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
