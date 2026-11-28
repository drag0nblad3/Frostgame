class_name ScenarioBriefing
extends RefCounted
## Player-facing descriptions of implemented behavior, not verbatim rulebook text.

const ENTRIES := {
	"sunken_streets": ["Sunken Streets", "Recover treasure from a collapsed city district.", "A sunken courtyard and raised streets offer alternate routes. Follow ramps and stairs to avoid steep climbing costs. Banks can block shots. Five treasures."],
	"treasure_skirmish": ["Frozen Ruins", "Explore the ruined streets and carry treasure off the table.", "Five treasures. Raised and sunken streets provide different sightlines; marked stairs and ramps provide cheaper routes. The central marker earns a campaign loot reroll. First collections can attract wandering monsters."],
	"mausoleum": ["The Mausoleum", "Loot a burial complex defended by skeletons.", "Six treasures; six initial skeletons. A further skeleton enters from a doorway after each Creature phase. No central treasure."],
	"living_museum": ["The Living Museum", "The statues are more dangerous than they look.", "Collecting treasure requires a Will roll (TN 8). Success awakens a remaining statue as a medium construct. Failed attempts spend an action."],
	"dreams_well": ["Well of Dreams and Sorrows", "Seek knowledge at an enchanted well.", "A wizard or apprentice touching the well may drink once as an action, earning 50 or 30 XP respectively. A figure pushed into the well is taken out of action."],
	"worm_hunts": ["The Worm Hunts", "The ground itself may conceal a predator.", "A giant worm can emerge near an unresolved treasure at the start of the Creature phase. The chance increases as treasures are first collected. Damaging or defeating the worm awards extra campaign XP."],
	"underground_library": ["The Library", "Recover arcane knowledge from a buried library.", "The central treasure must be broken free with a Fight roll (TN 14) before collection. Leave through the four marked doorways, not arbitrary table edges. Campaign treasure includes special library loot."],
	"haunted_houses": ["The Haunted Houses", "Search five abandoned huts.", "The first entry or magical movement of a hut's treasure can reveal a ghoul or wraith. Discovery of an undead occupant earns 15 XP. Once searched, the hut does not spawn another occupant."],
	"the_keep": ["The Keep", "Four arcane discs link distant parts of the battlefield.", "Ending a move on a disc can transport the figure to another disc. Treasure on a disc cannot be moved by spells. A wizard or apprentice gains 30 or 20 XP on their first successful transport."],
	"genie_in_the_bottle": ["Genie in the Bottle", "One treasure hides a dangerous lamp.", "A first pickup may release the genie; the last token guarantees discovery if it has not appeared. Mundane weapons cannot hurt it. After three victims it seeks an exit. The recovered lamp is worth 250 gc."],
	"silent_tower": ["The Silent Tower", "Explore a tower where magic fails.", "The tower and linked buildings cancel ongoing magic and suppress spellcasting, potions and magic gear. Treasure near the tower resists magical movement. First caster entry earns bonus XP. Use the ruined tower's stairs, walkways and adjoining buildings to reach the summit."],
	"complex_temple": ["The Complex Temple", "Break the guardians to reveal six treasures.", "Touching a guardian column triggers an opposed Fight roll without another action. Losing can cause damage; winning destroys the column and reveals its treasure. Eligible winners collect automatically. Caster challenges grant XP once each."]
}


static func title(id: String) -> String:
	return str(all_entries().get(id, ["Skirmish"])[0])


static func description(id: String) -> String:
	var entry: Array = all_entries().get(id, ["Skirmish", "Recover treasure or defeat the opposing warband.", ""])
	var description_text: String="%s\n\n%s" % [entry[1], entry[2]]
	if id in ["treasure_skirmish","sunken_streets","worm_hunts","genie_in_the_bottle","dreams_well","underground_library","silent_tower"]:
		description_text+="\n\nTreasure positions vary each battle; the map preview shows an example."
	return description_text


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
	if RedKingMadMan.active(s):
		var npc := s.figure(int(s.scenario_data.get("ryce_id",-1)))
		var rescue := s.treasure(int(s.scenario_data.get("ryce_token",-1)))
		if npc!=null and npc.in_play():
			text+=" | Ryce fleeing"
		elif rescue!=null:
			text+=" | Ryce "+("secured" if rescue.secured_by>=0 else ("escaped/lost" if rescue.lost else ("carried" if rescue.carrier_id>=0 else "unconscious")))
	if RealityCracks.id(s)>0:
		text+=" | Reality: "+str(RealityCracks.TITLES[RealityCracks.id(s)-1])
	if RedKingRingworld.active(s):
		text+=" | Key-Masters %d/4"%RedKingRingworld.remaining(s)
		var active_figure := s.active()
		if active_figure!=null:
			text+=" · "+("INSIDE" if active_figure.ring_side==1 else "OUTSIDE")
	if RedKingBridge.active(s):
		text+=" | Bridge exit only · Void TN16"
		var rolls: Array=s.scenario_data.get("bridge_veil_rolls",[])
		if rolls.size()==2:
			text+=" · Veil %d–%d"%[rolls[0],rolls[1]]
	if RedKingTethers.active(s):
		text+=" | Pylons: %d/5 intact"%RedKingTethers.remaining(s)
		if RedKingTethers.remaining(s)>0:
			text+=" · Exit locked"
		if not s.board.edge_links.is_empty():
			text+=" · Connected edges"
	if RedKingHill.active(s):
		text+=" | "+("Pyramid formed · Balance TN16" if RedKingHill.cracked(s) else "Reality unstable")
		if RedKingHill.guarded(s,s.treasure(0)):
			text+=" · Central treasure guarded"
	if RedKingSinkhole.active(s):
		text+=" | Gravity: 1″/turn · Casting −1/−2/−4"
	if RedKingHerded.active(s):
		text+=" | Veil %.0f/36″ · Exit south"%float(s.scenario_data.get("herd_veil",0.0))
	if RedKingMind.active(s):
		text="Mindscape · %d/8 memories · Turn %d/8"%[secured,mini(8,s.turn)]
	if RedKingFire.active(s):
		var artefact := s.treasure(0)
		if artefact!=null and artefact.frozen:
			text+=" | Artefact locked"
		text+=" | Corner exits"
	if RedKingVeil.active(s):
		text+=" | Veil %.0f / %.0f″ · Exit south"%[float(s.scenario_data.get("veil_y",12.0)),s.board.size.y]
	if RedKingInvestigations.active(s):
		var stands := 0
		for token in s.treasures:
			if token.investigation and token.unresolved():
				stands+=1
		text="%d secured · %d carried · %d stands · %s"%[secured,carrying,stands,"ALARM" if s.scenario_data.get("alarm",false) else "Undetected"]
		var edges: Dictionary=s.scenario_data.get("exit_edges",{})
		if edges.has(s.reaction_side):
			text+=" | Exit: "+", ".join(edges[s.reaction_side])
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
			elif s.scenario_data.has("genie_pending_finder"):
				text += " | Lamp found · release blocked"
			else:
				var genie := s.figure(s.genie_id)
				text += " | Genie %s" % ("escaping" if genie != null and genie.in_play() and s.genie_kills >= 3 else ("active" if genie != null and genie.in_play() else "gone"))
	return text


static func all_entries() -> Dictionary:
	var result := ENTRIES.duplicate(true)
	for pack: Dictionary in ContentProfile.registered().values():
		result.merge(pack.get("briefings",{}))
	return result


static func available_entries(profile: ContentProfile) -> Dictionary:
	return profile.filter("scenarios",all_entries())
