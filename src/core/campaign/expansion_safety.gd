class_name ExpansionSafety
extends RefCounted
## Never silently delete or replace a save's now-disabled content.
static func conflicts(before: ContentProfile,after: ContentProfile,roster: Dictionary,campaign: Dictionary) -> Array[String]:
	var errors := after.errors()
	for pack: String in before.enabled:
		if after.enabled.has(pack) or not before.packs.has(pack):
			continue
		var info: Dictionary=before.packs[pack]
		var content: Dictionary=info.get("content",{})
		var keys := {}
		for category: String in content:
			if category=="rules":
				continue
			for id: String in content[category]:
				keys[id]=true
				if category=="spells":
					keys["scroll_"+id]=true
					keys["grimoire_"+id]=true
		var used := {}
		_scan(roster,keys,used)
		_scan(campaign,keys,used)
		var name := str(info.get("name",pack))
		if not used.is_empty():
			var matches: Array[String]=[]
			for id: String in used:
				matches.append(id.replace("_"," "))
			errors.append("%s is still referenced by this save: %s."%[name,", ".join(matches)])
		if not content.get("rules",[]).is_empty() and int(campaign.get("games",0))>0:
			errors.append("%s changes persistent campaign rules; use a separate save to disable it."%name)
	return errors


static func _scan(value: Variant,keys: Dictionary,found: Dictionary) -> void:
	if value is String:
		if keys.has(value):
			found[value]=true
	elif value is Array:
		for child in value:
			_scan(child,keys,found)
	elif value is Dictionary:
		for key in value:
			if key=="expansions":
				continue
			_scan(key,keys,found)
			_scan(value[key],keys,found)
