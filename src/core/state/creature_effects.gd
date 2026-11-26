class_name CreatureEffects
extends RefCounted
## Trait-driven creature hooks; no effect on figures without the traits.
static func elemental_resistance(f: Figure) -> int:
	var value := 0
	for trait_id: String in f.def.traits:
		if trait_id.begins_with("elemental_resistance_"):
			value=maxi(value,int(trait_id.trim_prefix("elemental_resistance_")))
	return maxi(value,MagicEquipment.bonus(f,"elemental_resistance"))


static func after_damage(c: GameController,f: Figure) -> void:
	if not f.in_play() or not f.def.traits.has("pain_blink"):
		return
	var direction := Vector2.RIGHT.rotated(TAU*float(c.dice.pick(20))/20.0)
	ForcedRelocation.relocate(c,f,f.pos+direction*6.0)


static func activation(c: GameController,f: Figure) -> void:
	if not f.in_play():
		return
	for source in c.state.figures:
		if source==f or source.ring_side!=f.ring_side or not source.in_play():
			continue
		if source.def.traits.has("aura_of_pain") and Shooting.distance(f,source)<=6.0 and not f.is_demon() and not f.def.traits.has("undead") and not f.def.traits.has("construct"):
			var roll := c.dice.d20()
			var success := StatRoll.succeeds(roll,f.effective_will()+f.roll_penalty(),12)
			c.emit("creature_test",{"id":f.id,"source":source.id,"trait":"aura_of_pain","roll":roll,"success":success})
			if not success:
				c._hurt(f,2,source,false)
		if not f.in_play():
			return
		if source.def.traits.has("automatic_damage") and not f.def.traits.has("automatic_damage") and source.side!=f.side and Contact.figures_touch(f,source) and not f.spell_effects.has("plane_walk"):
			var damage := maxi(0,2-elemental_resistance(f))
			if not f.def.traits.has("antithetical_magic"):
				c._hurt(f,damage,source)
		if not f.in_play():
			return


static func end_turn(c: GameController) -> void:
	var db := c.state.creature_db
	if db==null:
		return
	for f in c.state.figures:
		if f.in_play() and f.def.traits.has("self_combustion") and c.dice.d20()==20:
			combust(c,f)


static func combust(c: GameController,f: Figure) -> void:
	var db := c.state.creature_db
	if db==null or not db.available("burning_man") or not f.in_play():
		return
	var enemies := Contact.enemies_of(c.state.figures,f)
	var replacement := db.get_def("burning_man")
	f.def=replacement
	f.health=replacement.health
	f.melee=replacement.melee_weapon(db.weapons)
	f.ranged=replacement.ranged_weapon()
	f.poisoned=false
	f.poison_weapon=""
	f.destroyed_weapons.clear()
	c.emit("creature_transformed",{"id":f.id,"type":replacement.id})
	for enemy in enemies:
		c._magic._shot(f,enemy,0,f.pos,true,true,"self_combustion")


static func after_fight(c: GameController,a: Figure,b: Figure,res: Dictionary,a_weapon: WeaponDef,b_weapon: WeaponDef) -> void:
	_melt(c,a,b,int(res["a_roll"]),a_weapon)
	_melt(c,b,a,int(res["b_roll"]),b_weapon)
	if a.in_play() and a.def.traits.has("suicide_attack") and int(res["b_dmg"])>0:
		c._hurt(a,a.health,a,false)
	if b.in_play() and b.def.traits.has("suicide_attack") and int(res["a_dmg"])>0:
		c._hurt(b,b.health,b,false)


static func _melt(c: GameController,attacker: Figure,target: Figure,roll: int,weapon: WeaponDef) -> void:
	if roll==1 and target.def.traits.has("melt_weapon") and not weapon.id in ["unarmed","natural"] and not WeaponActions.magical(attacker,weapon):
		WeaponActions.new(c).destroy(attacker,weapon.id)


## Only successfully cast spells call this hook; innate creature attacks do not.
static func reflection_target(c: GameController,caster: Figure,target: Figure,spell: String,roll: int = -1) -> Figure:
	if caster==target or not target.in_play() or not target.def.traits.has("spell_reflection"):
		return target
	var raw := c.dice.d20() if roll<0 else roll
	var reflected := raw>=16
	c.emit("spell_reflection",{"id":target.id,"caster":caster.id,"spell":spell,"roll":raw,"success":reflected})
	return caster if reflected else target
