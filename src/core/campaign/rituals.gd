class_name Rituals
extends RefCounted
## Campaign-only spell attempts keyed by battle number, caster and spell.
const BEFORE := ["brew_potion", "familiar", "animal_companion", "animate_construct", "raise_zombie", "awareness", "illusionary_soldier", "reveal_secret", "summon_demon"]
const AFTER := ["absorb_knowledge", "write_scroll", "miraculous_cure", "embed_enchantment"]
const ANIMALS := ["bear", "ice_toad", "snow_leopard", "wolf"]
const CONSTRUCTS := ["small_construct", "medium_construct", "large_construct"]


static func choices(d: Dictionary, caster: int, id: String) -> Array[String]:
	var out: Array[String] = []
	if d.is_empty() or caster < 0 or caster >= d["units"].size() or not d["spells"].has(id) or not ContentProfile.from_campaign(d).allows("spells",id):
		return out
	var u: Dictionary = d["units"][caster]
	if u["dead"] or u.get("dismissed", false) or int(u["miss"]) > 0 or u["type"] not in ["wizard", "apprentice"]:
		return out
	if RaggedWarbands.active(d) and id=="summon_demon":
		return out
	if not BEFORE.has(id) and not AFTER.has(id):
		return out
	if AFTER.has(id) and (int(d["games"]) == 0 or d.get("preparation_started", false)):
		return out
	if d.get("ritual_attempts", {}).has("%d:%s" % [caster, id]):
		return out
	var wizard: bool = u["type"] == "wizard"
	match id:
		"absorb_knowledge":
			if wizard and not u.get("last_knocked_out", false):
				out.append("")
		"familiar", "awareness", "reveal_secret":
			out.append("")
		"summon_demon":
			if BaseDemonRitual.available(d, caster):
				out.append("")
		"illusionary_soldier":
			if not d.has("prepared_illusion") or d["prepared_illusion"] == "":
				var db := FigureDb.load_files()
				for type: String in db.figures:
					var def := db.get_def(type)
					if def.role == "soldier" and type != "apothecary" and ContentProfile.from_campaign(d).allows("figures",type):
						out.append(type)
		"brew_potion":
			for p: String in CampaignInventory.LESSER:
				out.append(p)
			var catalog: Dictionary = JsonFile.read("res://data/potions.json")
			if wizard and not RedKingCampaign.economy_locked(d):
				for p: String in CampaignInventory.GREATER:
					if int(d["gold"]) >= int(catalog[p]["ingredients"]):
						out.append(p)
		"embed_enchantment":
			out.assign(EnchantmentRewards.choices(d))
		"write_scroll":
			for spell: String in d["spells"]:
				out.append(spell)
			for item: Dictionary in d["loot"]:
				if item["kind"] == "grimoire" and item.has("spell") and not out.has(item["spell"]):
					out.append(item["spell"])
		"animal_companion", "animate_construct":
			var companion := false
			var db := FigureDb.load_files()
			for member: Dictionary in d["units"]:
				if member["dead"] or member.get("dismissed", false):
					continue
				if member.get("companion_of", -1) == caster:
					companion = true
			if id == "animal_companion" and not companion:
				for type: String in ANIMALS:
					if BaseResources.fits(d, db, type):
						out.append(type)
			elif id == "animate_construct":
				for type: String in CONSTRUCTS:
					if BaseResources.fits(d, db, type):
						out.append(type)
		"raise_zombie":
			if not d.get("prepared_zombie", false):
				out.append("")
		"miraculous_cure":
			if wizard:
				for i in d["units"].size():
					var member: Dictionary = d["units"][i]
					if member.get("dismissed", false):
						continue
					if CampaignPotions.can_revive(d, member, FigureDb.load_files()) or (not member["dead"] and (int(member["injuries"]) > 0 or int(member["miss"]) > 0)):
						out.append(str(i))
	return out


static func attempt(d: Dictionary, caster: int, id: String, option: String, dice: Dice) -> bool:
	if not choices(d, caster, id).has(option):
		return false
	if id == "summon_demon":
		return BaseDemonRitual.attempt(d, caster, dice)
	var u: Dictionary = d["units"][caster]
	var mod := 0
	if BEFORE.has(id):
		d["preparation_started"] = true
	if id == "animate_construct":
		mod = -3 * CONSTRUCTS.find(option)
	if id == "brew_potion" and CampaignInventory.GREATER.has(option):
		var catalog: Dictionary = JsonFile.read("res://data/potions.json")
		d["gold"] = int(d["gold"]) - int(catalog[option]["ingredients"])
		mod = -4
	if id == "miraculous_cure" and d["units"][int(option)]["dead"]:
		mod = -4
	if not RedKingCampaign.economy_locked(d):
		mod += BaseRules.casting_bonus(str(d.get("base", "")), id) + BaseResources.casting_bonus(d, id)
	var attempts: Dictionary = d.get("ritual_attempts", {})
	attempts["%d:%s" % [caster, id]] = true
	d["ritual_attempts"] = attempts
	var raw := dice.d20()
	var total := CastingRoll.modified(raw, mod, u["type"] == "apprentice")
	var tn := int(d["spells"][id])
	var success := total >= tn
	d["last_report"].append("%s #%d: %s (%s) %d vs %d — %s." % [str(u["type"]).capitalize(), caster + 1, id.replace("_", " ").capitalize(), option, total, tn, "success" if success else "failed"])
	if not success:
		return true
	match id:
		"familiar":
			u["familiar"] = true
		"awareness":
			u["awareness"] = true
		"reveal_secret":
			d["revealed_secrets"] = int(d.get("revealed_secrets", 0)) + 1
		"illusionary_soldier":
			d["prepared_illusion"] = option
		"brew_potion":
			d["loot"].append({"kind": "potion", "potion": option, "owner": -1})
		"embed_enchantment":
			EnchantmentRewards.embed(d, int(option))
		"write_scroll":
			d["loot"].append({"kind": "scroll", "scroll": option, "owner": -1})
		"absorb_knowledge":
			d["xp"] = int(d["xp"]) + 40
		"animal_companion", "animate_construct":
			var member := {"type": option, "id": d["units"].size(), "miss": 0, "injuries": 0, "dead": false, "permanent_summon": true}
			if id == "animal_companion":
				member["companion_of"] = caster
			d["units"].append(member)
		"raise_zombie":
			d["prepared_zombie"] = true
		"miraculous_cure":
			var member: Dictionary = d["units"][int(option)]
			CampaignPotions.revive(member)
			member["injuries"] = 0
			member["injury_types"] = {}
	return true
