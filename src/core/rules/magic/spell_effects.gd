class_name SpellEffects
extends RefCounted
## Per-spell effects once a cast succeeds against a target in play.


## Applies the effect of `id`. Returns a bool to end the cast early, a Figure when
## the effect landed on a different target (redirected bolts), or null to continue.
static func apply(sa: SpellActions, s: GameState, p: Dictionary, f: Figure, t: Figure, id: String, result: Dictionary, power: int) -> Variant:
	match id:
		"fast_act":
			s.queue_fast(t, f.side)
		"time_store":
			f.spell_effects[id] = true
			f.stored_action_turn = s.turn
			f.actions_left = 0
		"time_walk":
			if f.last_time_walk == s.turn - 1:
				sa.c._hurt(f, 8, f, false)
			f.last_time_walk = s.turn
			if f.in_play():
				f.spell_effects[id] = true
				f.walk_phases.assign([Phase.APPRENTICE, Phase.SOLDIER])
		"invisibility", "true_sight":
			t.spell_effects[id] = true
			sa.illusions.sweep()
		"teleport", "leap":
			if p.get("effect",{}).has("floor_destination"):
				if id=="leap":
					LayeredLeap.apply(sa.c,t,p["effect"])
				else:
					LayeredMagic.apply_teleport(sa.c,t,p["effect"])
			else:
				sa.movement.move(t, p["at"], true)
		"suggestion":
			sa.resistance.attempt(t, int(result["roll"]), sa._suggestion_result.bind(t, p["at"]),(5 if t.def.traits.has("blood_marked") else 0)+RedKingGear.puppet_penalty(f,t))
			return true
		"push":
			sa.movement.push(f, t)
		"blink":
			sa.movement.blink(f,t,int(result["roll"]),bool(p.get("gem_extend",false)),bool(p.get("gem_reroll",false)))
		"transpose":
			sa.movement.transpose(f, t, s.figure(p["second"]), int(result["roll"]))
		"heal":
			sa._heal(t, 5)
		"mind_lock":
			if t.control_spell == "mind_control":
				sa.summons.release(t)
			t.spell_effects[id] = true
		"elemental_shield":
			t.elemental_shield = 3
		"elemental_bolt", "bone_dart", "poison_dart":
			t = ShotTarget.randomize(sa.c.dice, s.figures, t)
			t=CreatureEffects.reflection_target(sa.c,f,t,id)
			var old_health := t.health
			sa._shot(f, t, int(s.spell_catalog[id]["power"]), WizardEye.origin(s.board, f, t.pos, float(s.spell_catalog[id].get("range", 24.0))), id == "elemental_bolt", id == "elemental_bolt", id)
			if id == "poison_dart" and t.health < old_health:
				sa.c.poison(t)
			return t
		"call_storm":
			s.storm_penalty = mini(5, s.storm_penalty + 1)
		"blinding_light", "petrify":
			var bonus := 8 if id == "petrify" and t.def.traits.has("large") else 0
			sa.resistance.attempt(t, int(result["roll"]), sa._resisted_status.bind(t, id, int(result["roll"])), bonus)
			return true
		"banish":
			for other in s.figures:
				if other.in_play() and other.ring_side==f.ring_side and not ScenarioNull.muted(other) and other.is_demon() and Shooting.distance(f, other) <= 24.0 and LineOfSight.check(s.board, f.pos, other.pos).clear:
					sa._banish(f, other, int(result["roll"])+MagicEquipment.bonus(f,"banish_resistance_tn"), 4)
		"scatter_shot":
			for other in s.figures:
				if other.in_play() and other.ring_side==f.ring_side and other.side != f.side and Shooting.distance(f, other) <= 12 and LineOfSight.check(s.board, f.pos, other.pos).clear:
					sa._shot(f, CreatureEffects.reflection_target(sa.c,f,ShotTarget.randomize(sa.c.dice,s.figures,other),id), 0, f.pos, false, true, id)
		"destructive_sphere":
			for other in s.figures:
				if other != f and other.in_play() and other.ring_side==f.ring_side and Shooting.distance(f, other) <= 3:
					sa._direct_attack(f,CreatureEffects.reflection_target(sa.c,f,other,id),5,id)
		"plane_walk":
			sa.c._loot.drop_on_death(f)
			f.spell_effects[id] = true
			f.spell_effects.erase("bones_of_the_earth")
		"beauty":
			t.spell_effects[id] = int(result["roll"])
		"bones_of_the_earth":
			t.spell_effects[id] = true
		"possess":
			t.spell_effects[id] = f.id
		"slow", "curse", "furious_quill", "plague_of_insects":
			t.spell_effects[id] = int(result["roll"])
			if id == "slow" and t == s.active():
				t.actions_left = 0
		"elemental_ball":
			var affected: Array[Figure] = []
			for other in s.figures:
				if other.in_play() and other.ring_side==t.ring_side and Shooting.distance(t, other) <= 1.0 and (other == t or LineOfSight.check(s.board, t.pos, other.pos).clear):
					for member in ShotTarget.participants(s.figures, other):
						if not affected.has(member):
							affected.append(member)
			var ids: Array[int]=[]
			for other in affected:
				ids.append(other.id)
			s.scenario_data["rk_ball_queue"]={"caster":f.id,"center":t.id,"origin":t.pos,"targets":ids}
			sa._continue_ball()
		"destroy_undead":
			var raw := sa.c.dice.d20()
			var total := raw + t.effective_will() + t.roll_penalty() + MagicEquipment.bonus(t,"resistance")
			if not StatRoll.succeeds(raw, t.effective_will() + t.roll_penalty() + MagicEquipment.bonus(t,"resistance"), result["roll"]):
				sa.c._hurt(t, t.health if t.effective_will() <= 2 else maxi(0, int(result["roll"]) - total) * 3, f, false)
		"strike_dead":
			sa.resistance.attempt(t, int(result["roll"]), sa._resisted_death.bind(f, t), 0, true)
			return true
		"steal_health":
			sa.resistance.attempt(t, int(result["roll"]), sa._resisted_steal.bind(f, t))
			return true
		_:
			t.spell_effects[id] = true
	return null
