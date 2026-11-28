class_name Explainer
extends RefCounted
## Turns GameEvents into one-line log text, in our own words.


static func name_of(s: GameState, id: int) -> String:
	var f := s.figure(id)
	if f == null:
		return "?"
	return f.label() if f.side < 0 else "%s %s" % [s.side_names[f.side], f.label()]


static func text(s: GameState, e: GameEvent) -> String:
	var d := e.data
	match e.type:
		"swimming_roll":
			return "%s swims: %d %+d vs TN5 — %s."%[name_of(s,d["id"]),d["roll"],d["modifier"],"success" if d["success"] else "failed; loses actions"]
		"ryce_unconscious":
			return "Kalamon Ryce is unconscious. Carry him to safety."
		"ryce_escaped":
			return "Kalamon Ryce escapes into the ruins."
		"hrut_corner_choice":
			return "Choose a corner for your Hrut hunting party."
		"hrut_hunt":
			return "Hrut hunting parties arrive."
		"convergence_choice":
			return "Choose where %s lands in the convergence."%name_of(s,d["id"])
		"convergence_blocked":
			return "No legal contact placement for %s."%name_of(s,d["id"])
		"mad_man_crack":
			return "Reality twists: opposite edge regions exchange positions."
		"reality_crack":
			return "Reality Crack %d — %s."%[d["number"],d["name"]]
		"reality_stable":
			return "Reality stabilizes."
		"reality_school":
			return "%s magic: %+d casting this turn."%[str(d["school"]).capitalize(),d["bonus"]]
		"reality_null":
			return "Null wave: active spells cancelled and magic items suppressed this turn."
		"ring_switch":
			return "%s shifts to the %s of the ring."%[name_of(s,d["id"]),"inside" if d["plane"]==1 else "outside"]
		"ring_reinforcements":
			return "Hrut arrive at marker %d (%s)."%[d["marker"],"inside" if d["plane"]==1 else "outside"]
		"ring_finale":
			return "The four Key-Masters are destroyed. Frostgrave is saved; those left behind are lost." if d["success"] else "The warbands leave the Ringworld without destroying every Key-Master."
		"bridge_veil":
			return "The dimensional veil shifts to edge markers %d and %d."%[d["left"],d["right"]]
		"bridge_void":
			return "%s is forced toward the void: %s."%[name_of(s,d["id"]),"caught the edge" if d["success"] else "fell into the void"]
		"pylon_destroyed":
			return "A tether shatters, revealing treasure."
		"tethers_crack":
			return "The battlefield folds into three connected strips."
		"tethers_restored":
			return "All tethers destroyed. The battlefield returns to normal; exits open."
		"hill_crack":
			return "Reality cracks: the battlefield becomes four planar slopes."
		"hill_balance":
			return "%s attempts to keep balance: %s."%[name_of(s,d["id"]),"passed" if d["success"] else "fell downhill"]
		"sinkhole_contact":
			return "%s touches the anti-magic orb: %d damage."%[name_of(s,d["id"]),d["amount"]]
		"sinkhole_resist":
			return "%s attempts to resist the pull: %s."%[name_of(s,d["id"]),"success" if d["success"] else "failed"]
		"herd_veil":
			return "The veil advances %d inches. Escape before it reaches you!"%d["distance"]
		"herd_contact":
			return "%s is caught by the advancing veil."%name_of(s,d["id"])
		"mind_event":
			return "Mindscape event: %s of hearts."%d["card"]
		"mind_memory":
			return "%s recovers a memory."%name_of(s,d["id"])
		"mind_rewards":
			return "Memory reward cards: "+", ".join(d["cards"])
		"artefact_unlock":
			return "%s attempts to unlock the artefact: %s."%[name_of(s,d["id"]),"success" if d["success"] else "failed"]
		"portal_contact":
			return "%s touches a portal (%d elemental damage)."%[name_of(s,d["id"]),d["amount"]]
		"portal_emergence":
			return "A Hrut warrior emerges from a portal."
		"veil_contact":
			return "%s touches the veil and is taken out of action!"%name_of(s,d["id"])
		"fractured_reality":
			return "Reality fractures around %s (roll %d)."%[name_of(s,d["id"]),d["roll"]]
		"investigation_alarm":
			return "The camp is alerted: %s!"%d["reason"]
		"investigation_routes":
			var routes: Array[String]=[]
			for side in d["edges"]:
				routes.append("%s: %s"%[s.side_names[side],", ".join(d["edges"][side])])
			return "Reality shifts. Escape edges — "+"; ".join(routes)
		"stand_investigated":
			return "%s searches an offering: %s."%[name_of(s,d["id"]),("+%d gc if recovered"%d["gold"]) if int(d["gold"])>0 else "a cursed offering"]
		"stand_will":
			return "Offering Will test: %s."%("passed" if d["success"] else "failed")
		"investigation_skip":
			return "%s loses this activation."%name_of(s,d["id"])
		"troll_awake":
			return "The snow troll awakens!"
		"squatter_will":
			return "Central room Will test: %s."%("passed" if d["success"] else "failed")
		"pack_start":
			return "%s leads a pack of %d creatures." % [name_of(s, d["id"]), d["members"].size()]
		"null_field":
			return "%s loses ongoing magic in the null field." % name_of(s, d["id"])
		"tower_entered":
			return "%s enters the Silent Tower." % name_of(s, d["id"])
		"column_fight":
			return "%s fights a guardian column: %d vs %d (%s)." % [name_of(s, d["id"]), d["total"], d["column"], "won" if d["won"] else ("lost" if d["lost"] else "tie")]
		"column_opened":
			return "The column crumbles, revealing treasure."
		"genie_released":
			return "The lamp releases an angry genie!"
		"genie_flee":
			return "The genie has claimed three victims and seeks an exit."
		"genie_escaped":
			return "The genie escapes the ruins."
		"hut_discovered":
			return "Hut searched: %s." % ("empty" if d.get("creature", "") == "" else str(d["creature"]).capitalize())
		"disc_transport":
			return "Arcane disc transports a figure (roll %d)." % d["roll"]
		"disc_stay":
			return "Arcane disc: no transport (roll %d)." % d["roll"]
		"well_drink":
			return "%s drinks from the well (+%d campaign XP)." % [name_of(s, d["id"]), d["xp"]]
		"break_ice":
			return "%s tries to free the frozen treasure: %s." % [name_of(s, d["id"]), "success" if d["success"] else "failed"]
		"worm_emerges":
			return "A giant worm erupts beside treasure %d!" % (int(d["treasure"]) + 1)
		"weapon_selected":
			return "%s draws %s." % [name_of(s, d["id"]), str(d["weapon"]).replace("_", " ")]
		"telescope_used":
			return "%s use their telescope: +5 initiative." % s.side_names[d["side"]]
		"turn_start":
			var rolls: Array = d["rolls"]
			var parts: Array[String] = []
			for side in rolls.size():
				parts.append("%s %d" % [s.side_names[side], rolls[side]])
			return "Turn %d. Initiative: %s. %s go first." % [d["turn"], ", ".join(parts), s.side_names[d["order"][0]]]
		"phase":
			return "%s phase." % Phase.name_of(d["phase"])
		"group_begin":
			return "%s begin a group activation (%d figures)." % [s.side_names[d["side"]], d["ids"].size()]
		"group_second":
			return "Group movement complete. Choose second actions."
		"group_complete":
			return "Group activation complete."
		"early_phase_finished":
			return "%s pass their remaining early soldier activations." % s.side_names[d["side"]]
		"layered_move":
			return "%s moves to %s (%.1f inches)." % [name_of(s,d["id"]),str(d["surfaces"].back()).capitalize(),d["cost"]]
		"move":
			return "%s moves %.1f\"." % [name_of(s, d["id"]), d["cost"]]
		"fight":
			return "%s fights %s: %d vs %d (rolled %d and %d)." % [
				name_of(s, d["id"]), name_of(s, d["target"]),
				d["a_total"], d["b_total"], d["a_roll"], d["b_roll"]]
		"shoot":
			var cover := "" if d["mod"] == 0 else " (+%d cover)" % d["mod"]
			return "%s shoots %s: %d vs %d%s." % [
				name_of(s, d["id"]), name_of(s, d["target"]), d["s_total"], d["t_total"], cover]
		"treasure_pickup":
			return "%s collects treasure %d." % [name_of(s, d["id"]), d["treasure"] + 1]
		"treasure_drop":
			return "%s drops treasure %d." % [name_of(s, d["id"]), d["treasure"] + 1]
		"treasure_secured":
			return "%s secure treasure %d." % [s.side_names[d["side"]], d["treasure"] + 1]
		"treasure_lost":
			return "Treasure %d is lost." % (d["treasure"] + 1)
		"exit":
			return "%s leaves the table safely." % name_of(s, d["id"])
		"poison":
			return "%s is poisoned." % name_of(s, d["id"])
		"spell_expired":
			return "%s breaks free of %s." % [name_of(s, d["id"]), d["spell"]]
		"cast_roll":
			return "Casting %s: %d against %d." % [d["id"], d["total"], d["tn"]]
		"cast_result":
			return "%s %s %s (roll %d, %d HP spent)." % [name_of(s, d["id"]), "casts" if d["success"] else "fails", d["spell"], d["roll"], d["spent"]]
		"heal":
			return "%s regains %d Health." % [name_of(s, d["id"]), d["amount"]]
		"shield_absorb":
			return "%s's shield absorbs %d." % [name_of(s, d["id"]), d["amount"]]
		"creature_spawn":
			return "%s enters the ruins." % name_of(s, d["id"])
		"push_back":
			return "%s moves back from combat." % name_of(s, d["id"])
		"force_combat":
			return "%s intercepts a passing figure." % name_of(s, d["id"])
		"reload":
			return "%s reloads." % name_of(s, d["id"])
		"damage":
			return "%s takes %d damage (%d left)." % [name_of(s, d["id"]), d["amount"], d["health"]]
		"out_of_action":
			return "%s is out of action!" % name_of(s, d["id"])
		"game_over":
			if d["winner"] < 0:
				return "The game ends in a draw."
			return "%s win!" % s.side_names[d["winner"]]
	return ""
