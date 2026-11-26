class_name RedKingGear
extends RefCounted
## Persistent battle-local counters for Red King artefact weapons.
const SOUL := "gear_rk_soulchill_blade"
const WOE := "gear_rk_sword_of_woe"
const FIRE := "gear_rk_sword_of_elemental_fire"
const CHARGES := "rk_elemental_charge"


static func carried(f: Figure,id: String) -> bool:
	return ActiveGear.has(f,id) and not MagicEquipment.suppressed(f) and not f.destroyed_weapons.has("hand_weapon")


static func uses(f: Figure,id: String) -> bool:
	return f.melee != null and f.melee.id=="hand_weapon" and carried(f,id)


static func armour(attacker: Figure,target: Figure) -> int:
	return 9+target.effective_will() if uses(attacker,SOUL) else target.effective_armour()


static func woe_will(f: Figure) -> int:
	return 1 if carried(f,WOE) else 0


static func charge(f: Figure,school: String) -> void:
	if f.in_play() and school=="elementalist" and carried(f,FIRE):
		f.used_gear[CHARGES]=mini(5,int(f.used_gear.get(CHARGES,0))+1)


static func fire_damage(f: Figure,target: Figure) -> int:
	if not uses(f,FIRE) or target.def.traits.has("antithetical_magic"):
		return 0
	return maxi(0,int(f.used_gear.get(CHARGES,0))-CreatureEffects.elemental_resistance(target))


static func before_fight(figures: Array[Figure],f: Figure,target: Figure) -> Dictionary:
	var allies: Array[Figure]=[]
	var woe := carried(f,WOE)
	if woe and Melee.support(figures,f,target)>Melee.support(figures,target,f):
		for ally in figures:
			if ally!=f and ally.side==f.side and ally.in_play() and Contact.figures_touch(ally,target) and Contact.enemies_of(figures,ally).size()==1 and not RedKingTethers.pylon(ally) and not RedKingMadMan.hunter(ally):
				allies.append(ally)
	return {"soul":uses(f,SOUL),"woe":woe,"fire":uses(f,FIRE),"allies":allies}


static func after_fight(c: GameController,f: Figure,target: Figure,gear: Dictionary,raw: int,damage: int,actual: int,winner: int) -> void:
	if gear["soul"] and actual>0:
		if not target.def.traits.has("undead") and not target.def.traits.has("construct") and not target.def.traits.has("large"):
			target.used_gear["rk_soulchill_fight"]=int(target.used_gear.get("rk_soulchill_fight",0))+1
		if target.health<=0:
			f.used_gear["rk_soulchill_will"]=int(f.used_gear.get("rk_soulchill_will",0))+1
	if gear["fire"] and int(f.used_gear.get(CHARGES,0))>0:
		if raw==1:
			f.used_gear.erase(CHARGES)
			if f.in_play():
				c._hurt(f,1,f,false)
		elif damage>0:
			f.used_gear.erase(CHARGES)
	if gear["woe"]:
		if winner==target.id and f.in_play():
			c._hurt(f,2,f,false)
		var allies: Array=gear["allies"]
		if raw==1 and not allies.is_empty():
			var ally: Figure=allies[c.dice.pick(allies.size())]
			if ally.in_play():
				c._hurt(ally,10,f,false)


static func destiny_survival(roll: int) -> int:
	return roll-1 if roll>2 else roll


static func sticky(s: GameState,side: int) -> bool:
	for f in s.figures:
		if f.original_side==side and not f.out_of_action and ActiveGear.has(f,"gear_rk_sticky_finger_gloves"):
			return true
	return false


static func puppet(f: Figure) -> bool:
	return ActiveGear.has(f,"gear_rk_hypnotic_puppet") and not MagicEquipment.suppressed(f)


static func puppet_penalty(f: Figure,t: Figure) -> int:
	return -2 if puppet(f) and Shooting.distance(f,t)<=8.0 else 0
