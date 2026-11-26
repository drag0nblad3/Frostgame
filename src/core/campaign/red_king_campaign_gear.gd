class_name RedKingCampaignGear
extends RefCounted

const PLANT := "gear_rk_lifelong_plant"
const SHEARS := "gear_rk_mystic_shears"


static func accessible(d: Dictionary,id: String) -> int:
	for i in d.get("loot",[]).size():
		var item: Dictionary=d["loot"][i]
		if item.get("gear","")==id and item.get("unlocked",true) and not item.get("ragged_sealed",false):
			return i
	return -1


static func plant_choices(d: Dictionary,c: GameController,side: int) -> Array[int]:
	var out: Array[int]=[]
	if RedKingMind.active(c.state) or RaggedWarbands.active(d) or accessible(d,PLANT)<0:
		return out
	for f in c.state.figures:
		if f.original_side==side and f.campaign_id>=0 and f.def.role!="wizard" and f.out_of_action and not f.spell_effects.has("ring_left_behind"):
			out.append(f.campaign_id)
	return out


static func plant_roll(d: Dictionary,raw: int,report: Array[String]) -> int:
	var i := accessible(d,PLANT)
	if i<0:
		return raw
	report.append("Lifelong Plant: survival %d → %d."%[raw,raw+1])
	if raw==20:
		d["loot"].remove_at(i)
		report.append("The Lifelong Plant has withered.")
	return raw+1


static func shears_choices(d: Dictionary,caster: int,id: String,db: FigureDb) -> Array[int]:
	var out: Array[int]=[]
	if caster<0 or caster>=d.get("units",[]).size() or d["units"][caster]["type"]!="wizard" or not Rituals.BEFORE.has(id) or d.get("rk_shears_used",false) or accessible(d,SHEARS)<0:
		return out
	for unit: Dictionary in d["units"]:
		if not BaseResources.alive(unit) or int(unit.get("miss",0))>0 or unit.get("ragged_absent",false) or not BaseResources.specialist(unit,db):
			continue
		var def := db.get_def(unit["type"])
		if def.role!="soldier" or def.traits.has("animal") or def.traits.has("undead") or def.traits.has("construct") or def.traits.has("demon") or str(unit["type"])=="foulhorn":
			continue
		out.append(int(unit["id"]))
	return out


static func shears_injury(d: Dictionary,unit_id: int,dice: Dice) -> void:
	d["rk_shears_used"]=true
	var unit: Dictionary=d["units"][unit_id]
	var raw := dice.d20()
	if raw==20:
		unit["rk_shears_health"]=int(unit.get("rk_shears_health",0))+1
	else:
		unit["rk_shears_loss"]=1
	d["last_report"].append("Mystic Shears: %s #%d loses 1 %sHealth."%[str(unit["type"]).capitalize(),unit_id+1,"permanent " if raw==20 else "starting "])
