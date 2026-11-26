class_name WarbandAdvice
extends RefCounted
## Original tactical explanations backed by the actual roster and spell data.
const SCHOOLS := {
	"chronomancer":"Time magic, extra actions and movement manipulation.",
	"elementalist":"Direct magical attacks, battlefield walls and protection.",
	"enchanter":"Improve equipment, empower allies and manipulate treasure.",
	"illusionist":"Misdirection, stealth and repositioning.",
	"necromancer":"Undead servants, life-draining magic and ranged attacks.",
	"sigilist":"Runes, scrolls, counterspells and magical terrain.",
	"soothsayer":"Information, control and protective mental magic.",
	"summoner":"Summoned allies, demons and magical mobility.",
	"thaumaturge":"Healing, protection and countering hostile magic.",
	"witch":"Curses, potions, animal allies and obstructing terrain."
}
const ROLES := {
	"thug":"Free melee support. Useful for escorting casters or tying up opponents.",
	"thief":"Free, fast treasure runner. Less effective in melee than a thug.",
	"archer":"Affordable ranged specialist; can shoot without reloading.",
	"crossbowman":"Ranged damage specialist. Reloading uses an action.",
	"infantryman":"Strong melee damage for a modest price; no specialist slot.",
	"man_at_arms":"Durable standard soldier with a shield. Good bodyguard.",
	"treasure_hunter":"Fast, skilled treasure runner who can defend loot.",
	"knight":"High Fight and Armour; expensive and slower than most soldiers.",
	"barbarian":"Heavy melee damage and high Health, but lighter armour.",
	"ranger":"Fast ranged specialist with a hand weapon for melee.",
	"marksman":"Armoured crossbow specialist; slower, with reload requirements.",
	"tracker":"Fast bow specialist with a staff for defence.",
	"templar":"Heavy melee weapon and strong Fight; slower and expensive.",
	"war_hound":"Very fast, inexpensive fighter. Animals cannot carry treasure.",
	"apothecary":"High Will and Health, modest combat ability."
}
const EFFECTS := {
	"fleet_feet":"Improve a figure's movement. Useful for reaching or extracting treasure.",
	"slow":"Reduce an enemy's action economy.",
	"fast_act":"Change when a figure can act.",
	"elemental_bolt":"Powerful ranged magical shot against a single target.",
	"elemental_ball":"Magical area attack; use against clustered figures.",
	"elemental_shield":"Protect the caster with a temporary damage-absorbing shield.",
	"elemental_hammer":"Empower a weapon with extra magical damage.",
	"wall":"Place a temporary obstruction to control movement and sight.",
	"call_storm":"Impede ranged attacks across the battlefield.",
	"destructive_sphere":"Attack nearby figures with a magical area effect.",
	"enchant_armour":"Improve a figure's armour.",
	"enchant_weapon":"Give a weapon magical combat benefits.",
	"strength":"Improve a figure's fighting ability.",
	"telekinesis":"Move a treasure token without carrying it yourself.",
	"blink":"Magically reposition a figure.",
	"teleport":"Reposition the caster to a legal destination.",
	"transpose":"Exchange figures' positions.",
	"invisibility":"Make a figure harder for enemies to target.",
	"glow":"Make an enemy easier to hit with ranged attacks.",
	"fools_gold":"Manipulate the apparent value or presence of treasure.",
	"bone_dart":"Ranged magical attack with a lower base casting number than Elemental Bolt.",
	"raise_zombie":"Create an undead ally.",
	"animate_skull":"Create a small undead creature.",
	"steal_health":"Drain a target's vitality.",
	"control_undead":"Take control of an eligible undead creature.",
	"bridge":"Create a magical crossing.",
	"push":"Displace a target away from its position.",
	"explosive_rune":"Place a magical hazard.",
	"furious_quill":"Interfere with a target using magical harassment.",
	"write_scroll":"Prepare a spell scroll between battles.",
	"absorb_knowledge":"Gain campaign knowledge or experience.",
	"combat_awareness":"Improve a figure's combat ability.",
	"mind_control":"Attempt to control an enemy figure.",
	"wizard_eye":"Create a remote magical viewpoint for casting.",
	"reveal_secret":"Campaign preparation related to treasure.",
	"imp":"Summon an imp.",
	"summon_demon":"Summon a demon ally.",
	"control_demon":"Attempt to control an eligible demon.",
	"leap":"Move a figure magically across the battlefield.",
	"heal":"Restore lost Health.",
	"shield":"Increase protection against damage.",
	"blinding_light":"Blind a target, interfering with its attacks.",
	"dispel":"Remove an ongoing spell effect.",
	"circle_of_protection":"Place a ward against hostile creatures.",
	"banish":"Attack or remove eligible demons.",
	"destroy_undead":"Target undead creatures with holy magic.",
	"brew_potion":"Prepare a potion during campaign play.",
	"animal_companion":"Recruit an animal ally through a campaign ritual.",
	"control_animal":"Attempt to control an eligible animal.",
	"curse":"Reduce an enemy's effectiveness.",
	"fog":"Create an area that obstructs sight.",
	"mud":"Create difficult terrain.",
	"poison_dart":"Ranged magical attack with a poison effect."
}
const KINDS := {
	"counter":"Counter or modify magical effects.",
	"buff":"Change a figure's statistics or abilities.",
	"special":"Special action; exact targets depend on the spell.",
	"self_area":"Affects an area around the caster.",
	"area_shot":"Ranged attack that can affect several targets.",
	"shot":"Magical ranged attack.",
	"self":"Affects the caster.",
	"placement":"Place a figure, effect or magical terrain on the battlefield.",
	"ritual":"Campaign magic used outside ordinary combat.",
	"control":"Attempt to control an eligible target.",
	"treasure":"Manipulate treasure.",
	"touch":"Affects a nearby figure.",
	"resist":"Target may attempt to resist.",
	"heal":"Restore Health."
}


static func school(draft: WarbandDraft) -> String:
	var aligned: Array[String]=[]
	for id: String in draft.schools[draft.school]["aligned"]:
		aligned.append(id.capitalize())
	return "%s\nAligned (+2 TN): %s\nOpposed: %s (not available at creation). Other schools +4 TN."%[SCHOOLS.get(draft.school,""),", ".join(aligned),str(draft.schools[draft.school]["opposed"]).capitalize()]


static func stats(d: FigureDef) -> String:
	return "Move %d″ • Fight %+d • Shoot %+d\nArmour %d • Will %+d • Health %d"%[d.move,d.fight,d.shoot,d.armour,d.will,d.health]


static func loadout(d: FigureDef) -> String:
	var lines: Array[String]=[]
	for w in d.weapons:
		if w.id=="dagger":
			continue
		if w.is_ranged():
			lines.append("%s %d″, damage %+d%s"%[w.name,w.range_in,w.damage_mod,", reload" if w.needs_reload else ""])
		else:
			lines.append("%s: damage %+d%s"%[w.name,w.damage_mod,", incoming %+d"%w.enemy_damage_mod if w.enemy_damage_mod!=0 else ""])
	return ("Free dagger (−1 damage)" if lines.is_empty() else "; ".join(lines)+". Free dagger included.")


static func recruit(d: FigureDef) -> String:
	var gear: Array[String]=[]
	for weapon in d.weapons:
		gear.append(weapon.name)
	if d.shield:
		gear.append("Shield")
	return "%s · %d gc\n%s\n%s\n%s\n%s"%[d.name,d.cost,"Specialist (4 maximum)" if d.specialist else "Standard soldier",stats(d),", ".join(gear),ROLES.get(d.id,"")]


static func hire_reason(draft: WarbandDraft,d: FigureDef) -> String:
	if draft.soldiers.size()>=WarbandDraft.MAX_SOLDIERS:
		return "All soldier slots are filled."
	if d.specialist and draft.specialists()>=WarbandDraft.MAX_SPECIALISTS:
		return "All specialist slots are filled."
	if draft.cost()+d.cost>WarbandDraft.BUDGET:
		return "Need %d more gc."%(draft.cost()+d.cost-WarbandDraft.BUDGET)
	return ""


static func spell(draft: WarbandDraft,id: String) -> String:
	var info: Dictionary=draft.catalog[id]
	var tn := draft.casting_number(id)
	var base := int(info["number"])
	var chance := clampi(21-tn,0,20)*5
	var apprentice := clampi(19-tn,0,20)*5
	var description: String=EFFECTS.get(id,KINDS.get(str(info["kind"]),"Check the spell's targeting instructions in battle."))
	var result := "%s\n%s\nBase TN %d + school %d = %d\nUnmodified cast: %d%% wizard · %d%% apprentice\n\n%s"%[info["name"],ActionArt.spell_details(info,tn),base,tn-base,tn,chance,apprentice,description]
	if Rituals.BEFORE.has(id) or Rituals.AFTER.has(id):
		result+="\n\nCampaign ritual: "+("before a battle" if Rituals.BEFORE.has(id) else "after a battle")+"."
	elif info["kind"]=="unimplemented":
		result+="\n\nNot yet available in the digital game."
	return result
