class_name SpellUpkeep
extends RefCounted
## Spell upkeep: turn hooks, cancelling, Fate Stone insurance and rerolls, Shatterstar and equipment toggles.


static func answer_absorption(sa: SpellActions, use: bool) -> bool:
	var s := sa.c.state
	var offer: Dictionary=s.scenario_data.get("rk_spell_absorption",{})
	if offer.is_empty():
		return false
	var event: Dictionary=offer["event"]
	var t := s.figure(int(event["target"]))
	var f := s.figure(int(event["id"]))
	if t==null or f==null or t.side!=s.reaction_side:
		return false
	s.scenario_data.erase("rk_spell_absorption")
	sa._apply_shot(f,t,RedKingElemental.reduce(sa.c,t,int(offer["damage"]),int(use)),event)
	sa._continue_ball()
	sa.advance_shatter()
	return true


static func _resist_effect(sa: SpellActions, f: Figure, id: String) -> void:
	if f.in_play() and f.spell_effects.has(id) and StatRoll.succeeds(sa.c.dice.d20(), f.effective_will() + f.roll_penalty() + MagicEquipment.bonus(f,"resistance"), int(f.spell_effects[id])):
		f.spell_effects.erase(id)
		sa.c.emit("spell_expired", {"id": f.id, "spell": id})


static func on_activate(sa: SpellActions, f: Figure) -> void:
	sa.terrain.wall_activation(f)
	if not f.in_play():
		return
	if f.spell_effects.has("potion_invulnerability") and sa.c.dice.d20() >= 17:
		f.spell_effects.erase("potion_invulnerability")
		sa.c.emit("spell_expired", {"id": f.id, "spell": "potion_invulnerability"})
	sa._resist_effect(f, "furious_quill")


static func on_end_activation(sa: SpellActions, f: Figure) -> void:
	sa.shatter.clear()
	f.spell_effects.erase("potion_shatterstar")
	f.next_cast_gear = ""
	f.spell_effects.erase("potion_fire_breath")
	f.spell_effects.erase("potion_burrowing")
	f.petrified_skip = false
	sa._resist_effect(f, "slow")
	sa._resist_effect(f, "plague_of_insects")
	if f.in_play() and f.control_spell == "mind_control" and StatRoll.succeeds(sa.c.dice.d20(), f.effective_will() + f.roll_penalty() + MagicEquipment.bonus(f,"resistance"), f.control_roll):
		sa.summons.release(f)


static func on_end_turn(sa: SpellActions) -> void:
	if not sa.c.state.board.floor_layout.is_empty():
		LayeredBridge.expire(sa.c)
	sa.terrain.expire()
	for f in sa.c.state.figures:
		if f.spell_effects.erase("plane_walk"):
			sa.c.emit("spell_expired", {"id": f.id, "spell": "plane_walk"})
		sa._resist_effect(f, "curse")
		sa._resist_effect(f, "blinding_light")


static func can_cancel(sa: SpellActions, target: int) -> bool:
	var f := sa.c.state.active()
	var t := sa.c.state.figure(target)
	return sa.c.can_act() and f != null and t != null and sa.summons.cancelable(f, t)


static func cancel(sa: SpellActions, target: int) -> bool:
	if not sa.can_cancel(target):
		return false
	var f := sa.c.state.active()
	sa.c._spend(f)
	sa.summons.cancel(f, sa.c.state.figure(target))
	return true


static func can_insure(sa: SpellActions) -> bool:
	var p := sa.c.state.pending_cast
	if p.is_empty() or p.get("scroll", false):
		return false
	var failed: bool = int(p["total"]) < int(p["tn"]) or (p["id"] == "summon_demon" and int(p["raw"]) == 1)
	return failed and ScrollActions.has_scroll(sa.c.state.figure(p["caster"]), p["id"])


static func insure(sa: SpellActions) -> bool:
	if not sa.can_insure():
		return false
	var p := sa.c.state.pending_cast
	var roll := ScrollActions.consume_roll(sa.c.state.figure(p["caster"]),p["id"])
	if roll<=0:
		return false
	p["scroll"] = true
	p.erase("vampire_amount")
	p["total"] = roll
	return sa.finish(0)


static func reroll_fate(sa: SpellActions) -> bool:
	var p := sa.c.state.pending_cast
	if p.is_empty() or p.get("scroll", false):
		return false
	var f := sa.c.state.figure(p["caster"])
	if not ActiveGear.spend(f, "gear_fate_stone"):
		return false
	var old := int(p["raw"])
	var raw := sa.c.dice.d20()
	p["raw"] = raw
	p["total"] = int(p["total"]) + raw - old
	sa.c.emit("fate_reroll", {"id": f.id, "first": old, "second": raw})
	return true


static func _dispatch_shatter(sa: SpellActions, entry: Dictionary) -> void:
	var f := sa.c.state.active()
	if f == null or not f.in_play() or f.id != int(entry["caster"]):
		return
	var t := sa.c.state.figure(entry["target"])
	if t == null or not t.in_play():
		return
	if entry["second"] >= 0 and not sa.c.state.figure(entry["second"]).in_play():
		return
	sa._authorize_roll(entry["id"], entry["target"], entry["at"], entry["rotated"], entry["second"], entry["effect"])


static func advance_shatter(sa: SpellActions) -> void:
	if sa.shatter.resolving or not sa.c.state.pending_cast.is_empty() or sa.c.awaiting_reaction():
		return
	if not sa.shatter.next.is_empty():
		var entry := sa.shatter.next
		sa.shatter.next = {}
		sa.shatter.resolving = true
		sa._dispatch_shatter(entry)
		sa.shatter.resolving = false
	if sa.c.state.pending_cast.is_empty() and not sa.c.awaiting_reaction():
		sa.shatter.spent = false


static func single_shatter(sa: SpellActions) -> bool:
	if sa.shatter.first.is_empty():
		return false
	var entry := sa.shatter.first
	sa.shatter.first = {}
	var f := sa.c.state.active()
	if f == null or not f.in_play() or f.id != int(entry["caster"]):
		return false
	f.spell_effects.erase("potion_shatterstar")
	sa._dispatch_shatter(entry)
	return true


static func toggle_golden_fang(sa: SpellActions) -> bool:
	var p := sa.c.state.pending_cast
	if p.get("id","")!="animate_skull" or RedKingMaterials.fang_count(sa.c.state.figure(p["caster"]))<=0:
		return false
	p["golden_fang"]=not p.get("golden_fang",false)
	return true


static func toggle_gem(sa: SpellActions, option: String) -> bool:
	var p := sa.c.state.pending_cast
	if p.get("id","")!="blink" or option not in ["gem_extend","gem_reroll"]:
		return false
	var f := sa.c.state.figure(p["caster"])
	if f==null or not ActiveGear.has(f,PowerPool.GEM) or MagicEquipment.suppressed(f):
		return false
	p[option]=not p.get(option,false)
	return true
