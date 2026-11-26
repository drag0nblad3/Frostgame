class_name WeaponActions
extends RefCounted

var c: GameController


func _init(controller: GameController) -> void:
	c = controller


static func magical(t: Figure, w: WeaponDef) -> bool:
	if ScenarioNull.muted(t):
		return false
	if not w.is_ranged() and t.spell_effects.get("potion_fairy_dust", "") == w.id:
		return true
	if t.spell_effects.has("enchant_weapon") and (w == t.ranged or (t.ranged == null and w == t.melee)):
		return true
	for item in t.items:
		if item.get("gear_info", {}).get("type", "") == w.id:
			return true
	return false


func options(f: Figure) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t in c.state.figures:
		if t == f or not t.in_play() or ScenarioNull.muted(t) or not IllusionRules.visible_to(c.state.figures, f, t) or not WizardEye.visible(c.state.board, f, t.pos):
			continue
		for w in t.def.weapons:
			if w.id in ["natural", "unarmed"] or t.destroyed_weapons.has(w.id) or magical(t, w):
				continue
			out.append({"kind": "weapon", "target": t.id, "weapon": w.id, "label": "%s #%d — %s" % [t.label(), t.id, w.name]})
	return out


func destroy(t: Figure, id: String) -> void:
	if t.destroyed_weapons.has(id):
		return
	t.destroyed_weapons.append(id)
	if t.melee.id == id:
		t.melee = t.unarmed_weapon
		for w in t.def.weapons:
			if w.melee and not t.destroyed_weapons.has(w.id):
				t.melee = w
				break
	if t.ranged != null and t.ranged.id == id:
		t.ranged = null
		for w in t.def.weapons:
			if w.is_ranged() and not t.destroyed_weapons.has(w.id):
				t.ranged = w
				t.loaded = true
				break
	c.emit("weapon_destroyed", {"id": t.id, "weapon": id})


static func magic_attack(f: Figure, w: WeaponDef) -> bool:
	if ScenarioNull.muted(f):
		return false
	return (w == f.melee and ActiveGear.has(f, "gear_construct_hammer")) or f.is_demon() or f.def.traits.has("magic_attack") or magical(f, w) or f.spell_effects.get("potion_fairy_dust", "") == w.id or (f.spell_effects.has("elemental_hammer") and (w == f.ranged or f.ranged == null))
