class_name RedKingElemental
extends RefCounted

const AMULET := "gear_rk_amulet_of_elemental_energy_absorption"
const ARMED := "rk_elemental_absorb_armed"


static func arm(c: GameController) -> bool:
	var f := c.state.active()
	if f==null or not f.in_play() or not ActiveGear.ready(f,AMULET) or c.awaiting_reaction() or not c.state.pending_cast.is_empty():
		return false
	f.used_gear[ARMED]=not f.used_gear.get(ARMED,false)
	c.emit("gear_used",{"id":f.id,"gear":AMULET,"armed":f.used_gear[ARMED]})
	return true


static func reduce(c: GameController,t: Figure,damage: int,choice: int=-1) -> int:
	if damage<=0:
		return 0
	if ActiveGear.has(t,AMULET) and not MagicEquipment.suppressed(t):
		var armed: bool=t.used_gear.get(ARMED,false) if choice<0 else choice==1
		if choice<0 and t.side!=c.state.reaction_side and damage>=4 and damage>=t.health:
			armed=true
		if armed and ActiveGear.spend(t,AMULET):
			t.used_gear.erase(ARMED)
			var raw := c.dice.d20()
			if raw<=16:
				c.emit("gear_used",{"id":t.id,"gear":AMULET,"roll":raw,"absorbed":damage})
				return 0
			for i in t.items.size():
				if t.items[i].get("gear","")==AMULET:
					t.items.remove_at(i)
					break
			c.emit("gear_used",{"id":t.id,"gear":AMULET,"roll":raw,"destroyed":true})
			return damage+3
		damage=maxi(0,damage-1)
	return PotionActions.absorb(t,damage)


static func weapon_parts(attacker: Figure,target: Figure,damage: int,raw: int,ranged: bool) -> Vector2i:
	if damage<=0:
		return Vector2i.ZERO
	var hammer := 5 if attacker.spell_effects.has("elemental_hammer") and (ranged or attacker.ranged==null) and not target.def.traits.has("antithetical_magic") else 0
	var sword := RedKingGear.fire_damage(attacker,target) if not ranged and raw!=1 else 0
	var elemental := mini(damage,hammer+sword)
	var normal := damage-elemental
	return Vector2i(normal,maxi(0,elemental-mini(hammer,CreatureEffects.elemental_resistance(target))))


static func weapon_damage(c: GameController,attacker: Figure,target: Figure,damage: int,raw: int,ranged: bool,choice: int=-1) -> int:
	var parts := weapon_parts(attacker,target,damage,raw,ranged)
	return parts.x+reduce(c,target,parts.y,choice)
