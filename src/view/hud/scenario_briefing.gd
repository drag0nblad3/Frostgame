class_name ScenarioBriefing
extends RefCounted
## Player-facing descriptions of implemented behavior, not verbatim rulebook text.

const ENTRIES := {
	"sunken_streets": ["Sunken Streets", "Recover treasure from a collapsed city district.", "A sunken courtyard and raised streets offer alternate routes. Follow ramps and stairs to avoid steep climbing costs. Banks can block shots. Five treasures."],
	"treasure_skirmish": ["Frozen Ruins", "Explore the ruined streets and carry treasure off the table.", "Five treasures. The central marker earns a campaign loot reroll. First collections can attract wandering monsters."],
	"mausoleum": ["The Mausoleum", "Loot a burial complex defended by skeletons.", "Six treasures; six initial skeletons. A further skeleton enters from a doorway after each Creature phase. No central treasure."],
	"living_museum": ["The Living Museum", "The statues are more dangerous than they look.", "Collecting treasure requires a Will roll (TN 8). Success awakens a remaining statue as a medium construct. Failed attempts spend an action."],
	"dreams_well": ["Well of Dreams and Sorrows", "Seek knowledge at an enchanted well.", "A wizard or apprentice touching the well may drink once as an action, earning 50 or 30 XP respectively. A figure pushed into the well is taken out of action."],
	"worm_hunts": ["The Worm Hunts", "The ground itself may conceal a predator.", "A giant worm can emerge near an unresolved treasure at the start of the Creature phase. The chance increases as treasures are first collected. Damaging or defeating the worm awards extra campaign XP."],
	"underground_library": ["The Library", "Recover arcane knowledge from a buried library.", "The central treasure must be broken free with a Fight roll (TN 14) before collection. Leave through the four marked doorways, not arbitrary table edges. Campaign treasure includes special library loot."],
	"haunted_houses": ["The Haunted Houses", "Search five abandoned huts.", "The first entry or magical movement of a hut's treasure can reveal a ghoul or wraith. Discovery of an undead occupant earns 15 XP. Once searched, the hut does not spawn another occupant."],
	"the_keep": ["The Keep", "Four arcane discs link distant parts of the battlefield.", "Ending a move on a disc can transport the figure to another disc. Treasure on a disc cannot be moved by spells. A wizard or apprentice gains 30 or 20 XP on their first successful transport."],
	"genie_in_the_bottle": ["Genie in the Bottle", "One treasure hides a dangerous lamp.", "A first pickup may release the genie; the last token guarantees discovery if it has not appeared. Mundane weapons cannot hurt it. After three victims it seeks an exit. The recovered lamp is worth 250 gc."],
	"silent_tower": ["The Silent Tower", "Explore a tower where magic fails.", "The tower and linked buildings cancel ongoing magic and suppress spellcasting, potions and magic gear. Treasure near the tower resists magical movement. First caster entry earns bonus XP. Climb the exposed terraces to reach the summit."],
	"complex_temple": ["The Complex Temple", "Break the guardians to reveal six treasures.", "Touching a guardian column triggers an opposed Fight roll without another action. Losing can cause damage; winning destroys the column and reveals its treasure. Eligible winners collect automatically. Caster challenges grant XP once each."]
}


static func title(id: String) -> String:
	return str(ENTRIES.get(id, ["Skirmish"])[0])


static func description(id: String) -> String:
	var entry: Array = ENTRIES.get(id, ["Skirmish", "Recover treasure or defeat the opposing warband.", ""])
	return "%s\n\n%s" % [entry[1], entry[2]]


static func progress(s: GameState) -> String:
	var secured := 0
	var carrying := 0
	var ground := 0
	var lost := 0
	for token in s.treasures:
		if token.secured_by >= 0:
			secured += 1
		elif token.lost:
			lost += 1
		elif token.carrier_id >= 0:
			carrying += 1
		else:
			ground += 1
	var text := "%d secured · %d carried · %d unclaimed" % [secured, carrying, ground]
	if lost > 0:
		text += " · %d lost" % lost
	match s.scenario_special:
		"haunted_houses": text += " | Huts %d/5" % s.discovered_huts.size()
		"complex_temple":
			var closed := 0
			for token in s.treasures:
				if token.frozen and token.unresolved():
					closed += 1
			text += " | Guardians %d" % closed
		"underground_library":
			var central := s.treasure(0)
			if central != null and central.frozen and central.unresolved():
				text += " | Central frozen"
		"worm_hunts": text += " | Worm %s" % ("emerged" if s.worm_spawned else "hidden")
		"genie_in_the_bottle":
			if s.lamp_token < 0:
				text += " | Lamp hidden"
			else:
				var genie := s.figure(s.genie_id)
				text += " | Genie %s" % ("escaping" if genie != null and genie.in_play() and s.genie_kills >= 3 else ("active" if genie != null and genie.in_play() else "gone"))
	return text
