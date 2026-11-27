class_name ContentProfile
extends RefCounted
## Selection of optional content for one save or simulation.
const PATH := "res://data/expansions.json"
static var _registry: Dictionary={}
static var _loaded := false
var enabled: Array[String]=[]
var packs: Dictionary
var _owners := {}


func _init(ids: Array=[],registry: Dictionary={}) -> void:
	packs=registry if not registry.is_empty() else registered()
	for id in ids:
		if id is String and not enabled.has(id):
			enabled.append(id)
	enabled.sort()
	for pack_id: String in packs:
		var content: Dictionary=packs[pack_id].get("content",{})
		for category: String in content:
			for id: String in content[category]:
				var key := category+":"+id
				if not _owners.has(key):
					_owners[key]=[]
				_owners[key].append(pack_id)


static func registered() -> Dictionary:
	if not _loaded:
		var data: Dictionary=JsonFile.read(PATH)
		_registry=data.get("packs",{})
		_loaded=true
	return _registry


static func from_campaign(data: Dictionary) -> ContentProfile:
	return ContentProfile.new(data.get("expansions",[]))


static func playable(pack: Dictionary) -> bool:
	return str(pack.get("status","ready")) in ["ready","playtest"]


func errors() -> Array[String]:
	var result: Array[String]=[]
	for id in enabled:
		if not packs.has(id):
			result.append("Missing content pack: "+id)
			continue
		if not playable(packs[id]):
			result.append("%s is not playable yet."%packs[id].get("name",id))
		for required: String in packs[id].get("requires",[]):
			if not enabled.has(required):
				result.append("%s requires %s."%[packs[id].get("name",id),required])
	return result


func allows(category: String,id: String) -> bool:
	var owners: Array=_owners.get(category+":"+id,[])
	for owner: String in owners:
		if not enabled.has(owner) or not playable(packs[owner]):
			return false
	return true


func rule(id: String) -> bool:
	return _owners.has("rules:"+id) and allows("rules",id)


func filter(category: String,catalog: Dictionary) -> Dictionary:
	var result := {}
	for id: String in catalog:
		if allows(category,id):
			result[id]=catalog[id]
	return result


func item_allowed(id: String) -> bool:
	if id.begins_with("scroll_") or id.begins_with("grimoire_"):
		return allows("spells",id.trim_prefix("scroll_").trim_prefix("grimoire_"))
	return allows("potions",id) and allows("magic_equipment",id)


func same(ids: Array) -> bool:
	return enabled==ContentProfile.new(ids,packs).enabled
