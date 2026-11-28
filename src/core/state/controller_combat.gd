class_name ControllerCombat
extends RefCounted
## Fighting, shooting, damage and poison for GameController. Mutates state only on the controller's behalf.


static func fight(c: GameController, target_id: int) -> bool:
	if not c.can_fight(target_id):
		return false
	var f := c.state.active()
	var t := c.state.figure(target_id)
	CreatureBot.apply_mask_cost(c.state,f,t)
	c._spend(f)
	c._fate_combat.start(f, t, "fight")
	return true


static func finish_fate_fight(c: GameController, f: Figure, t: Figure, res: Dictionary) -> void:
	res["id"] = f.id
	res["target"] = t.id
	res["a_weapon"]=f.melee.id if f.melee!=null else "unarmed"
	res["b_weapon"]=t.melee.id if t.melee!=null else "unarmed"
	c.emit("fight", res)
	c._magic.illusions.reveal(f)
	c._magic.illusions.reveal(t)
	var a_weapon := f.melee
	var b_weapon := t.melee
	if RedKingMadMan.is_ryce(t):
		if int(res["b_dmg"])>0:
			RedKingMadMan.knock_out(c,t,f)
		return
	var a_gear := RedKingGear.before_fight(c.state.figures,f,t)
	var b_gear := RedKingGear.before_fight(c.state.figures,t,f)
	var before_a := f.health
	var before_b := t.health
	c._weapon_damage(t,RedKingElemental.weapon_damage(c,f,t,int(res["b_dmg"]),int(res["a_roll"]),false,int(res.get("elemental_choices",{}).get(t.id,-1)),int(res.get("b_hammer",0))),f,a_weapon)
	c._weapon_damage(f,RedKingElemental.weapon_damage(c,t,f,int(res["a_dmg"]),int(res["b_roll"]),false,int(res.get("elemental_choices",{}).get(f.id,-1)),int(res.get("a_hammer",0))),t,b_weapon)
	var actual := res.duplicate()
	actual["a_dmg"]=maxi(0,before_a-f.health)
	actual["b_dmg"]=maxi(0,before_b-t.health)
	RedKingGear.after_fight(c,f,t,a_gear,int(res["a_roll"]),int(res["b_dmg"]),int(actual["b_dmg"]),int(res["winner"]))
	RedKingGear.after_fight(c,t,f,b_gear,int(res["b_roll"]),int(res["a_dmg"]),int(actual["a_dmg"]),int(res["winner"]))
	CreatureEffects.after_fight(c,f,t,actual,a_weapon,b_weapon)
	if int(res.get("b_hammer",0))>0:
		WeaponEnchantment.remove(f,a_weapon.id,WeaponEnchantment.HAMMER)
	if int(res.get("a_hammer",0))>0:
		WeaponEnchantment.remove(t,b_weapon.id,WeaponEnchantment.HAMMER)
	if f.in_play() and t.in_play() and Contact.figures_touch(f,t) and int(res["winner"]) >= 0:
		var winner := c.state.figure(res["winner"])
		if not RedKingTethers.pylon(f) and not RedKingTethers.pylon(t) and (winner.side >= 0 or RedKingHill.is_herald(c.state,winner) or (RedKingRingworld.active(c.state) and RedKingRingworld.key_master(winner))):
			c.state.push_winner = winner.id
			c.state.push_loser = t.id if winner == f else f.id
			if RedKingHill.is_herald(c.state,winner) or RedKingRingworld.key_master(winner):
				c._displacement.push(false)
	elif f.in_play() and t.in_play() and Contact.figures_touch(f,t) and int(res["winner"])<0 and not RedKingTethers.pylon(f) and not RedKingTethers.pylon(t):
		var first: Figure=null
		var other: Figure=null
		if CombatDisplacement.boots(f) and f.side>=0:
			first=f
			other=t
		if CombatDisplacement.boots(t) and t.side>=0 and (first==null or t.side==c.state.reaction_side):
			first=t
			other=f
		if first!=null:
			c.state.push_winner=first.id
			c.state.push_loser=other.id
			c.state.push_tie=true
			c.state.push_tie_second=CombatDisplacement.boots(other) and other.side>=0
			if first.side!=c.state.reaction_side and first!=c.state.active():
				c._auto_tie_withdraw()


static func _auto_tie_withdraw(c: GameController) -> void:
	var f := c.state.figure(c.state.push_winner)
	if f!=null and f.treasure_id>=0:
		for distance in [3.0,2.0,1.0,0.5]:
			if c.resolve_push(true,distance):
				return
	c.stay_in_combat()


static func shoot(c: GameController, target_id: int,wraith: bool=false,ammo: bool=false) -> bool:
	if not c.can_shoot(target_id,wraith,ammo):
		return false
	var f := c.state.active()
	var t := c.state.figure(target_id)
	c._magic.beauty.authorize(f, ShotTarget.participants(c.state.figures, t), c._shoot_authorized.bind(f,t,wraith,ammo))
	return true


static func _shoot_authorized(c: GameController, f: Figure,t: Figure,wraith: bool=false,ammo: bool=false) -> void:
	if not f.in_play() or not t.in_play() or (wraith and not ActiveGear.spend(f,Shooting.WRAITH)):
		return
	if ammo and not MagicAmmo.spend(f):
		return
	c._magic.illusions.reveal(f)
	var declared := t.id
	t = ShotTarget.randomize(c.dice, c.state.figures, t)
	c._spend(f)
	if f.ranged.needs_reload:
		f.loaded = false
	c._fate_combat.start(f,t,"shoot",declared,wraith,ammo)


static func finish_fate_shot(c: GameController, f: Figure, t: Figure, res: Dictionary, declared: int) -> void:
	res["declared"] = declared
	res["id"] = f.id
	res["target"] = t.id
	res["weapon"]=f.ranged.id if f.ranged!=null else "bow"
	c.emit("shoot", res)
	c._weapon_damage(t,RedKingElemental.weapon_damage(c,f,t,int(res["dmg"]),int(res["s_roll"]),true,int(res.get("elemental_choices",{}).get(t.id,-1)),int(res.get("hammer",0))),f,f.ranged)
	if f.spell_effects.get("potion_fairy_dust", "") == f.ranged.id:
		f.spell_effects.erase("potion_fairy_dust")
	if f.ranged != null:
		WeaponEnchantment.remove(f,f.ranged.id,WeaponEnchantment.HAMMER)
	if res.get("wraith",false) and f.in_play():
		var raw := c.dice.d20()
		var success := StatRoll.succeeds(raw,f.effective_will()+f.roll_penalty(),8)
		if not success:
			f.spell_effects["curse"]=14
		c.emit("creature_test",{"id":f.id,"trait":"wraith_bow","roll":raw,"success":success})


## Named reload_weapon because Script.reload() would shadow a static reload().
static func reload_weapon(c: GameController) -> bool:
	if not c.can_reload():
		return false
	var f := c.state.active()
	if f.moves_taken > 0:
		c._spend(f)
	else:
		f.actions_left -= 1
	f.loaded = true
	c.emit("reload", {"id": f.id})
	return true


static func _hurt(c: GameController, f: Figure, dmg: int, by: Figure, combat: bool = true) -> void:
	if RedKingMadMan.is_ryce(f):
		return
	if dmg <= 0 or not f.in_play() or (f.spell_effects.has("plane_walk") and by != f) or (combat and by != f and IllusionRules.phantom(by)):
		return
	if IllusionRules.phantom(f):
		c._magic.summons.vanish(f)
		return
	if combat and f.elemental_shield > 0:
		var absorbed := mini(dmg, f.elemental_shield)
		f.elemental_shield -= absorbed
		dmg -= absorbed
		c.emit("shield_absorb", {"id": f.id, "amount": absorbed})
		if dmg == 0:
			return
	var was_wounded := f.wounded()
	var out := Damage.apply(f, dmg)
	if not was_wounded and f.wounded() and c.state.active()==f:
		f.actions_left=mini(f.actions_left,0 if f.acted or f.moves_taken>0 else 1)
	if f.familiar and f.health <= 1:
		f.familiar = false
		f.def = f.def.with_bonuses({"health": -2})
		c.emit("familiar_lost", {"id": f.id})
	if combat and not out and by != f and by.def.traits.has("poison"):
		c.poison(f)
	c.emit("damage", {"id": f.id, "by": by.id, "amount": dmg, "health": f.health})
	if out:
		c._loot.drop_on_death(f)
		c.emit("out_of_action", {"id": f.id, "by": by.id})
		ScenarioGenie.record_kill(c, f, by)
		RedKingSquatter.record_kill(c,f,by)
		RedKingTethers.destroyed(c,f,by)
		c._magic.summons.enforce_illusion_limit(f)
	else:
		CreatureEffects.after_damage(c,f)


static func poison(c: GameController, f: Figure) -> void:
	if not f.in_play() or f.immune_to_poison() or f.poisoned:
		return
	f.poisoned = true
	if c.state.active() == f:
		f.actions_left = mini(f.actions_left, 0 if f.acted or f.moves_taken > 0 else 1)
	c.emit("poison", {"id": f.id})


static func fight_hand(c: GameController, id: int) -> bool:
	if not c.can_fight_hand(id):
		return false
	var f := c.state.active()
	var t := c.state.figure(id)
	var support := 0
	for ally in c.state.figures:
		if ally != f and ally.in_play() and ally.side == f.side and (ally == t or Contact.figures_touch(ally, t)):
			support += 2
	var attack := c.dice.d20() + mini(f.effective_fight() + f.melee.fight_mod + MagicEquipment.bonus(f, "fight", f.melee.id) + mini(6, support), 10) + f.roll_penalty()
	var defend := c.dice.d20()
	c._spend(f)
	var freed := attack >= defend and attack + f.melee.damage_mod + MagicEquipment.bonus(f, "damage", f.melee.id) > 10
	if freed:
		t.spell_effects.erase("bones_of_the_earth")
		c.emit("spell_expired", {"id": t.id, "spell": "bones_of_the_earth"})
	if defend >= attack:
		c._hurt(f, maxi(0, defend - f.effective_armour() + f.melee.enemy_damage_mod), t)
	c.emit("fight_hand", {"id": f.id, "target": id, "attack": attack, "defence": defend, "freed": freed})
	return true


static func _weapon_damage(c: GameController, t: Figure, dmg: int, f: Figure, w: WeaponDef) -> void:
	var old := t.health
	c._hurt(t, dmg, f)
	if t.health<old:
		RedKingHill.balance(c,t)
	if t.health < old and f.poison_weapon == w.id:
		f.poison_weapon = ""
		c.poison(t)
