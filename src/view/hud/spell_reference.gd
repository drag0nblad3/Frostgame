class_name SpellReference
extends RefCounted
## Original reference for the implemented digital spells. Read once per process.
static var _entries: Dictionary


static func entry(id: String) -> Dictionary:
	if _entries.is_empty():
		_entries=JsonFile.read("res://data/spell_reference.json")
	return _entries.get(id,{})


static func text(id: String) -> String:
	var d := entry(id)
	if d.is_empty():
		return "Check the spell's targeting instructions."
	return "TARGET & RANGE\n%s\n\nEFFECT\n%s\n\nDURATION & RESTRICTIONS\n%s"%[d["target"],d["effect"],d["duration"]]


static func odds(tn: int,modifier: int=0) -> int:
	return clampi(21-tn+modifier,0,20)*5


static func append_details(parent: Node,id: String) -> void:
	var d := entry(id)
	for key in ["target","effect","duration"]:
		WorkshopUI.label(parent,{"target":"TARGET & RANGE","effect":"EFFECT","duration":"DURATION & RESTRICTIONS"}[key],18,WorkshopUI.GOLD)
		WorkshopUI.label(parent,str(d.get(key,"See targeting instructions.")),25)
	if Rituals.BEFORE.has(id) or Rituals.AFTER.has(id):
		WorkshopUI.label(parent,"Campaign: "+("before battle" if Rituals.BEFORE.has(id) else "after battle")+".",21,WorkshopUI.MUTED)


static func battle_entries(s: GameState,f: Figure,legal: Array[String]) -> Array[Dictionary]:
	var ids: Array[String]=[]
	for id: String in s.spellbooks.get(f.side,{}):
		ids.append(id)
	for key in legal:
		if not ids.has(key):
			ids.append(key)
	var out: Array[Dictionary]=[]
	for key in ids:
		var id := "enchant_weapon" if key=="enchant_ammo" else key
		if not s.spell_catalog.has(id):
			continue
		var info: Dictionary=s.spell_catalog[id]
		var known: bool=s.spellbooks.get(f.side,{}).has(id)
		var tn := int(s.spellbooks.get(f.side,{}).get(id,info["number"]))
		out.append({"key":key,"id":id,"name":"Enchant Ammunition" if key=="enchant_ammo" else str(info["name"]),"school":info["school"],"tn":tn,"known":known,"chance":odds(tn,-2 if f.def.role=="apprentice" else 0),"legal":legal.has(key),"ritual_only":info["kind"]=="ritual"})
	return out


static func guide_pages(catalog: Dictionary) -> Array[Dictionary]:
	var pages: Array[Dictionary]=[]
	for school: String in WarbandAdvice.SCHOOLS:
		var sections: Array[String]=[]
		for id: String in catalog:
			var info: Dictionary=catalog[id]
			if info["school"]!=school:
				continue
			sections.append("%s · Base TN %d\n%s"%[info["name"],info["number"],text(id)])
		pages.append({"title":school.capitalize()+" spells","text":"\n\n────────────────\n\n".join(sections)})
	return pages
