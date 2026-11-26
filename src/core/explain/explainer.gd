class_name Explainer
extends RefCounted
## Turns GameEvents into one-line log text, in our own words.


static func name_of(s: GameState, id: int) -> String:
	var f := s.figure(id)
	if f == null:
		return "?"
	return "%s %s" % [s.side_names[f.side], f.label()]


static func text(s: GameState, e: GameEvent) -> String:
	var d := e.data
	match e.type:
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
