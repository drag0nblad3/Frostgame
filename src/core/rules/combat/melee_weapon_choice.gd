class_name MeleeWeaponChoice
extends RefCounted
## Select actual carried melee weapons before either opposed die is rolled.
## A plain pending record also supports save/resume and command replay.
const KEY := "melee_weapon_choice"

static func pending(c: GameController) -> Dictionary:
	return c.state.scenario_data.get(KEY,{})

static func options(f: Figure) -> Array[WeaponDef]:
	var out: Array[WeaponDef]=[]
	if f==null:
		return out
	for w in f.def.weapons:
		if w.melee and not f.destroyed_weapons.has(w.id) and not out.has(w):
			out.append(w)
	if out.is_empty() and f.unarmed_weapon!=null:
		out.append(f.unarmed_weapon)
	return out

static func offer(c: GameController,a: Figure,b: Figure) -> bool:
	var owner: Figure=null
	if c.state.reaction_side>=0:
		for f in [a,b]:
			if f.side==c.state.reaction_side and options(f).size()>1:
				owner=f
				break
	if owner==null:
		return false
	c.state.scenario_data[KEY]={"a":a.id,"b":b.id,"owner":owner.id}
	c.emit("melee_weapon_offer",{"id":owner.id,"opponent":b.id if owner==a else a.id})
	return true

static func choose(c: GameController,id: String) -> bool:
	var p:=pending(c)
	if p.is_empty():
		return false
	var a:=c.state.figure(int(p["a"]))
	var b:=c.state.figure(int(p["b"]))
	var f:=c.state.figure(int(p["owner"]))
	if f==null or a==null or b==null or not a.in_play() or not b.in_play() or f.side!=c.state.reaction_side:
		return false
	for w in options(f):
		if w.id!=id:
			continue
		c.state.scenario_data.erase(KEY)
		WeaponEnchantment.migrate(f)
		if f.melee!=w:
			f.melee=w
			c.emit("weapon_selected",{"id":f.id,"weapon":id})
		var other:=b if f==a else a
		if other.side!=c.state.reaction_side:
			auto_select(c,other,f)
		c._fate_combat.roll(a,b,"fight")
		return true
	return false

## Use a deterministic evaluation of the weapon's offence, defence and
## ability to harm an immune target. Ties retain the equipped weapon.
static func auto_select(c: GameController,f: Figure,enemy: Figure) -> void:
	var available:=options(f)
	if available.size()<2:
		return
	WeaponEnchantment.migrate(f)
	var original:=f.melee
	var best:=original
	var value:=-INF
	for w in available:
		f.melee=w
		var score:=float(w.fight_mod+MagicEquipment.bonus(f,"fight",w.id)+(1 if WeaponEnchantment.active(f,w) else 0))*2.0+float(w.damage_mod+MagicEquipment.bonus(f,"damage",w.id)-w.enemy_damage_mod)
		if (enemy.def.traits.has("immune_normal") or enemy.spell_effects.has("potion_invulnerability")) and not WeaponActions.magic_attack(f,w):
			score-=20.0
		if score>value or (is_equal_approx(score,value) and w==original):
			best=w
			value=score
	f.melee=best
	if best!=original:
		c.emit("weapon_selected",{"id":f.id,"weapon":best.id})
