class_name SpellResolution
extends RefCounted
## Resolving a declared cast: casting roll, costs, then the effect (see SpellEffects) and its follow-ups.


static func _finish_one(sa: SpellActions, health: int) -> bool:
	var s := sa.c.state
	var p := s.pending_cast
	if p.is_empty() or health < 0 or health > sa.max_empowerment():
		return false
	var f := s.figure(p["caster"])
	var t := s.figure(p["target"])
	var id: String = p["id"]
	var stolen := VampireStaff.amount(sa.c,p,true)
	var result := CastingRoll.resolve(int(p["total"])+stolen,p["tn"],health, PowerPool.cast_resources(f,id), false, 100 if id == "summon_demon" else 18)
	if p.get("scroll", false):
		result = {"success": true, "roll": int(p["total"]), "health_spent": 0, "failure_damage": 0}
	elif id == "summon_demon" and int(p["raw"]) == 1:
		result["success"] = false
	s.pending_cast = {}
	VampireStaff.spend(sa.c,f,p,stolen)
	var power := PowerPool.spend(f,int(result["health_spent"]),id)
	var hp := int(result["health_spent"]) - power
	if MagicEquipment.bonus(f,"cast_failure_cap")>0:
		result["failure_damage"]=mini(int(result["failure_damage"]),1)
	sa.c._hurt(f, hp + int(result["failure_damage"]) + (2 if p.get("cordial", false) else 0), f, false)
	sa.c.emit("cast_result", {"id": f.id, "spell": id, "target": t.id, "success": result["success"], "roll": result["roll"], "spent": hp, "power": power, "tn": p["tn"], "failure_damage": result["failure_damage"], "scroll": p.get("scroll", false)})
	if id == "summon_demon" and int(p["raw"]) == 1 and not p.get("scroll", false):
		sa.summons.miscast_demon(f)
		return true
	if not result["success"]:
		return true
	RedKingGear.charge(f,str(s.spell_catalog[id].get("school","")))
	if id in ["dispel", "spell_eater"]:
		sa.counter.apply(p["effect"])
		return true
	if id in ["power_word", "draining_word"]:
		WordMagic.apply(s, f, id, p["effect"]["chosen"])
		sa.c.emit("spell_effect", {"id": f.id, "spell": id})
		return true
	if id == "wizard_eye":
		sa.eye.create(f, p["effect"])
		return true
	if id == "crumble":
		sa.crumble.apply(p["effect"]["piece"])
		return true
	if id == "decay":
		sa.weapons.destroy(t, p["effect"]["weapon"])
		return true
	if id in ["telekinesis", "fools_gold"]:
		var token:=s.treasure(p["effect"]["token"])
		if p["effect"].has("surface_id"):
			sa.treasure_magic.apply_floor(f,id,token,p["at"],p["effect"]["surface_id"],int(result["roll"]))
		else:
			sa.treasure_magic.apply(f,id,token,p["at"],int(result["roll"]))
		return true
	if id=="bridge" and p.get("effect",{}).has("layered_bridge"):
		var bridge: Dictionary=p["effect"]["layered_bridge"]
		if LayeredBridge.can_apply(sa.c,bridge) and (not bridge.get("extended",false) or ActiveGear.spend(f,TerrainMagic.EXTENDED)):
			LayeredBridge.apply(sa.c,bridge)
		return true
	if TerrainMagic.SPELLS.has(id):
		var extended: bool=p.get("effect",{}).get("extended_bridge",false)
		if not extended or ActiveGear.spend(f,TerrainMagic.EXTENDED):
			sa.terrain.apply(f,id,p["at"],p["rotated"],int(result["roll"]),extended,str(p.get("effect",{}).get("surface_id","")))
		return true
	if SummonActions.PLACEMENT.has(id):
		var effect: Dictionary=p.get("effect",{})
		var surface:=str(effect.get("surface_id",""))
		var height:=0.0
		if not surface.is_empty():
			var layout:=s.board.floor_geometry()
			var node:=layout.node(surface,p["at"])
			if not sa.summons.can_place_floor(f,id,node):
				return true
			height=layout.height(node)
		sa.summons.spawn(f,id,p["at"],int(result["roll"]),int(p["tn"]),bool(p.get("golden_fang",false)),surface,height)
		sa.illusions.sweep()
		return true
	if not t.in_play():
		return true
	if id not in ["elemental_ball","elemental_bolt","scatter_shot","destructive_sphere"] and CircletDefence.blocks(sa.c,t,id):
		return true
	if id in ["heal","mind_lock","elemental_shield","blinding_light","petrify","bones_of_the_earth","slow","curse","furious_quill","plague_of_insects","strike_dead","steal_health","suggestion","blink"]:
		t=CreatureEffects.reflection_target(sa.c,f,t,id)
	if id not in ["elemental_ball","elemental_bolt","scatter_shot","destructive_sphere"] and CircletDefence.blocks(sa.c,t,id):
		return true
	if SummonActions.CONTROL.has(id):
		sa.summons.apply_control(f, t, id, int(result["roll"]))
		return true
	if id=="enchant_weapon" and p.get("effect",{}).get("magic_ammo",false):
		if MagicAmmo.add(t):
			sa.c.emit("spell_effect",{"id":t.id,"spell":"enchant_weapon"})
		return true
	var early: Variant = SpellEffects.apply(sa, s, p, f, t, id, result, power)
	if early is bool:
		return early
	if early is Figure:
		t = early
	sa.c.emit("spell_effect", {"id": t.id, "spell": id})
	return true


static func _heal(sa: SpellActions, t: Figure, amount: int) -> void:
	var old := t.health
	t.health = mini(t.def.health, t.health + amount)
	if t.health > old:
		t.poisoned = false
	sa.c.emit("heal", {"id": t.id, "amount": t.health - old})


static func _shot(sa: SpellActions, f: Figure, t: Figure, power: int, origin: Variant = null, elemental: bool = false, magical: bool = true, spell: String = "") -> void:
	if CircletDefence.blocks(sa.c,t,spell):
		return
	if f.ring_side!=t.ring_side or (RedKingTethers.pylon(t) and not magical) or not t.in_play() or t.spell_effects.has("plane_walk") or ScenarioNull.muted(t) or (magical and t.def.traits.has("antithetical_magic")):
		return
	var s := sa.c.state
	# The explosion's origin can be an actual point in space, not a
	# projected x/z point reinterpreted as the uppermost floor.
	var from: Vector2=WizardEye.origin(s.board,f,t.pos) if origin==null else (Vector2(origin.x,origin.z) if origin is Vector3 else origin)
	var los:=LineOfSight.check(s.board,from,t.pos,f) if s.board.floor_layout.is_empty() else LineOfSight.check_figures(s.board,f,t)
	if not s.board.floor_layout.is_empty() and origin==null and not spell.is_empty() and spell!="elemental_ball":
		var remote: Variant=WizardEye.floor_origin(s.board,f,Vector3(t.pos.x,t.elevation,t.pos.y),float(s.spell_catalog.get(spell,{}).get("range",24.0)))
		if remote!=null:
			origin=remote
	if origin is Vector3 and not s.board.floor_layout.is_empty():
		los=LineOfSight.Result.new()
		los.clear=LineOfSight.floor_ray(s.board,s.board.floor_geometry(),origin,Vector3(t.pos.x,t.elevation+1.0,t.pos.y),f,false)
	if s.board.floor_layout.is_empty() and not los.clear and spell in ["elemental_bolt","bone_dart","poison_dart","elemental_ball"] and from==f.pos and TigerEye.witness(s.board,f,t.pos,float(s.spell_catalog[spell].get("range",24.0)))!=null:
		los.clear=true
		los.intervening+=1
	if not s.board.floor_layout.is_empty() and not los.clear and spell in ["elemental_bolt","bone_dart","poison_dart","elemental_ball"] and not origin is Vector3 and TigerEye.floor_witness(s.board,f,Vector3(t.pos.x,t.elevation,t.pos.y),float(s.spell_catalog[spell].get("range",24.0)))!=null:
		los.clear=true
		los.intervening+=1
	if not los.clear and (not s.board.floor_layout.is_empty() or RedKingHill.cracked(s)):
		return
	var mod := Shooting.target_mod(los) + (1 if f.moves_taken > 0 else 0)
	if t.def.traits.has("large"):
		mod -= 2
	var ar := sa.c.dice.d20()
	var dr := sa.c.dice.d20()
	var a := ar - (2 if RealityCracks.low_gravity(f) else 0) + mini(power + (3 if HolyLantern.glow(t) else 0), 10) + f.roll_penalty()
	var d := dr + mini(t.effective_fight() + Melee.secret_hrut_bonus(t,f) + mod, 10) + t.roll_penalty() + t.shooting_defence_penalty()
	var won := a > d
	if s.critical_hits:
		won = dr != 20 and (ar == 20 or won)
	var dmg := Damage.amount(a, 0, t.effective_armour() + (CreatureEffects.elemental_resistance(t) if elemental else 0), ar, s.critical_hits and not t.def.traits.has("immune_critical")) if won else 0
	if not magical and t.def.traits.has("immune_normal"):
		dmg = 0
	if elemental and MagicEquipment.bonus(t, "absorb") > 0:
		dmg = ceili(dmg / 2.0)
	var event := {"id":f.id,"target":t.id,"attack":a,"defence":d,"spell":spell,"origin":from if s.board.floor_layout.is_empty() else (origin if origin is Vector3 else null)}
	# Only these spell pipelines can safely suspend without skipping subsequent effects.
	if elemental and spell in ["elemental_bolt","elemental_ball"] and dmg>0 and t.side==s.reaction_side and ActiveGear.ready(t,RedKingElemental.AMULET):
		s.scenario_data["rk_spell_absorption"]={"event":event,"damage":dmg}
		sa.c.emit("elemental_offer",{"id":t.id,"damage":dmg,"spell":spell})
		return
	if elemental:
		dmg=RedKingElemental.reduce(sa.c,t,dmg)
	sa._apply_shot(f,t,dmg,event)


static func _apply_shot(sa: SpellActions, f: Figure,t: Figure,dmg: int,event: Dictionary) -> void:
	event["dmg"]=dmg
	sa.c.emit("spell_shot",event)
	var old_health := t.health
	sa.c._hurt(t,dmg,f)
	if t.health<old_health:
		RedKingHill.balance(sa.c,t)


static func _continue_ball(sa: SpellActions) -> void:
	var s := sa.c.state
	var queue: Dictionary=s.scenario_data.get("rk_ball_queue",{})
	if queue.is_empty():
		return
	var f := s.figure(int(queue["caster"]))
	while not queue["targets"].is_empty():
		var other := s.figure(int(queue["targets"].pop_front()))
		if other==null:
			continue
		var recipient := CreatureEffects.reflection_target(sa.c,f,other,"elemental_ball")
		var origin: Variant=f.pos if recipient==f or other.id==int(queue["center"]) else (queue["origin"] if s.board.floor_layout.is_empty() else queue.get("origin_world",queue["origin"]))
		sa._shot(f,recipient,5,origin,true,true,"elemental_ball")
		if s.scenario_data.has("rk_spell_absorption"):
			return
	s.scenario_data.erase("rk_ball_queue")


static func _banish(sa: SpellActions, f: Figure, t: Figure, roll: int, threshold: int) -> void:
	t=CreatureEffects.reflection_target(sa.c,f,t,"banish")
	var raw := sa.c.dice.d20()
	var will := t.effective_will() + t.roll_penalty() + MagicEquipment.bonus(t,"resistance")
	if not StatRoll.succeeds(raw, will, roll):
		sa.c._hurt(t, t.health if t.effective_will() <= threshold else maxi(0, roll - raw - will) * 3, f, false)


static func _direct_attack(sa: SpellActions, f: Figure,t: Figure,power: int,spell: String="") -> void:
	if CircletDefence.blocks(sa.c,t,spell):
		return
	if ScenarioNull.muted(t) or t.def.traits.has("antithetical_magic"):
		return
	var a := sa.c.dice.d20() + power
	var d := sa.c.dice.d20() + t.effective_fight() + t.roll_penalty()
	sa.c.emit("magic_impact",{"id":t.id,"spell":spell,"hit":a>d})
	if a > d:
		sa.c._hurt(t, maxi(0, a - t.effective_armour()), f, false)


static func _resisted_status(sa: SpellActions, success: bool, t: Figure, id: String, roll: int) -> void:
	if success or not t.in_play():
		return
	t.spell_effects[id] = roll
	if id == "petrify":
		t.petrified_skip = true
	sa.c.emit("spell_effect", {"id": t.id, "spell": id})


static func _resisted_steal(sa: SpellActions, success: bool, f: Figure, t: Figure) -> void:
	if success or not t.in_play():
		return
	sa.c._hurt(t, 3, f, false)
	if f.in_play():
		sa._heal(f, 3)
	sa.c.emit("spell_effect", {"id": t.id, "spell": "steal_health"})


static func _resisted_death(sa: SpellActions, success: bool, f: Figure, t: Figure) -> void:
	if not success and t.in_play():
		sa.c._hurt(t, t.health, f, false)


static func _suggestion_result(sa: SpellActions, success: bool, t: Figure, at: Vector2) -> void:
	if success or not t.in_play():
		return
	sa.c._loot.drop_on_death(t)
	if at != t.pos:
		sa.movement.move(t, at)
