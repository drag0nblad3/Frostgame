class_name RollSummary
extends RefCounted
## Read actual resolved dice; never generate cosmetic or misleading rolls.


static func describe(s: GameState, event: GameEvent) -> String:
	var d := event.data
	match event.type:
		"fight":
			var result := "Tie" if int(d["winner"]) < 0 else Explainer.name_of(s, int(d["winner"])) + " wins"
			return "MELEE · %s\n%s: %d → %d   |   %s: %d → %d\nDamage before absorption: %d to %s / %d to %s" % [result, Explainer.name_of(s, d["id"]), d["a_roll"], d["a_total"], Explainer.name_of(s, d["target"]), d["b_roll"], d["b_total"], d["a_dmg"], Explainer.name_of(s,d["id"]), d["b_dmg"], Explainer.name_of(s,d["target"])]
		"shoot":
			return "SHOT · %s\n%s: %d → %d   |   %s: %d → %d\nDamage before absorption: %d" % ["Potential damage" if int(d["dmg"]) > 0 else "No damage", Explainer.name_of(s, d["id"]), d["s_roll"], d["s_total"], Explainer.name_of(s, d["target"]), d["t_roll"], d["t_total"], d["dmg"]]
		"cast_result":
			var spell_name := str(d["spell"]).replace("_", " ").capitalize()
			if d.get("scroll",false):
				return "SPELL · %s · Scroll used\nCasting result %d · No empowerment spent"%[spell_name,d["roll"]]
			var text := "SPELL · %s · %s\nResolved roll %d / TN %d · %d Health and %d power spent" % [spell_name, "Success" if d["success"] else "Failed", d["roll"], d["tn"], d["spent"], d.get("power", 0)]
			if int(d.get("failure_damage",0))>0:
				text+="\nFailure damage: %d"%d["failure_damage"]
			return text
		"spell_shot":
			return "SPELL ATTACK\n%s: %d   |   %s: %d" % [Explainer.name_of(s, d["id"]), d["attack"], Explainer.name_of(s, d["target"]), d["defence"]]
	return ""
