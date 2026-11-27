class_name SpellReference
extends RefCounted
## Shared player-facing explanations of the implemented digital rules.
static var _reference: Dictionary=JsonFile.read("res://data/spell_reference.json")
static var _catalog: Dictionary=JsonFile.read("res://data/spells.json")


static func catalog() -> Dictionary:
	return _catalog


static func entry(id: String) -> Dictionary:
	return _reference.get(id,{})


static func chance(id: String,tn: int,modifier: int) -> int:
	var successes := 0
	for raw in range(1,21):
		if id=="summon_demon" and raw==1:
			continue
		if raw+mini(modifier,10)>=tn:
			successes+=1
	return successes*5


static func describe(id: String) -> String:
	var d := entry(id)
	if d.is_empty():
		return "No reference available for this spell."
	return "TARGET: %s\nEFFECT: %s\nDURATION: %s"%[d["target"],d["effect"],d["duration"]]


static func populate(parent: Node,id: String,spec: Dictionary,ammo: bool=false) -> void:
	var d := entry(id)
	if d.is_empty():
		WorkshopUI.label(parent,"No detailed reference available.",23)
		return
	WorkshopUI.label(parent,"EFFECT",18,WorkshopUI.GOLD)
	WorkshopUI.label(parent,"Enchant ammunition for an allied bow or crossbow user. Use the enchanted ammunition attack when available." if ammo else str(d["effect"]),25)
	WorkshopUI.label(parent,"TARGET & RANGE",18,WorkshopUI.GOLD)
	WorkshopUI.label(parent,str(d["target"]),23)
	WorkshopUI.label(parent,"DURATION",18,WorkshopUI.GOLD)
	WorkshopUI.label(parent,str(d["duration"]),23)
	if spec["kind"]!="ritual":
		WorkshopUI.label(parent,"Cast: d20 against TN. Gear and conditions modify the roll. Success can still require a separate attack or resistance test.",19,WorkshopUI.MUTED)
	else:
		WorkshopUI.label(parent,"Campaign ritual: no Health empowerment; normally one attempt per caster per preparation cycle.",19,WorkshopUI.MUTED)
