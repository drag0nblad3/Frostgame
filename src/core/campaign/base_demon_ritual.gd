class_name BaseDemonRitual
extends RefCounted
## The Summoning Circle requires two successive wizard casts, without Health spending.


static func available(d: Dictionary, caster: int) -> bool:
	if not BaseResources.owns(d, "summoning_circle") or not d.get("spells", {}).has("control_demon"):
		return false
	return d["units"][caster]["type"] == "wizard" and d.get("prepared_demon", {}).is_empty()


static func attempt(d: Dictionary, caster: int, dice: Dice,shears_target: int=-1) -> bool:
	if not available(d, caster) or not d["spells"].has("summon_demon"):
		return false
	var attempts: Dictionary = d.get("ritual_attempts", {})
	var key := "%d:summon_demon" % caster
	if attempts.has(key):
		return false
	attempts[key] = true
	d["ritual_attempts"] = attempts
	d["preparation_started"] = true
	var raw := dice.d20()
	var total := CastingRoll.modified(raw,BaseResources.casting_bonus(d,"summon_demon")+(2 if shears_target>=0 else 0))
	if shears_target>=0:
		RedKingCampaignGear.shears_injury(d,shears_target,dice)
	var tn := int(d["spells"]["summon_demon"])
	if raw == 1 or total < tn:
		d["last_report"].append("Summoning Circle: summon failed (%d vs %d)." % [total, tn])
		return true
	var margin := total - tn
	var type := "major_demon" if margin >= 13 else ("minor_demon" if margin >= 6 else "imp")
	var control := CastingRoll.modified(dice.d20(), BaseResources.casting_bonus(d, "control_demon"))
	var control_tn := int(d["spells"]["control_demon"])
	if control < control_tn:
		d["last_report"].append("Summoning Circle: %s summoned, but control failed (%d vs %d)." % [type.capitalize(), control, control_tn])
		return true
	d["prepared_demon"] = {"type": type, "caster": caster, "control_roll": maxi(control, 14)}
	d["last_report"].append("Summoning Circle: %s will join the next battle." % type.replace("_", " ").capitalize())
	return true
