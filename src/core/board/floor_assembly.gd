class_name FloorAssembly
extends RefCounted
## Expand immutable local floor kits into the existing canonical floor layout.
## A prefix namespaces local IDs; references to outside surfaces stay global.
## Coordinates are quarter-turned about the origin, then translated.


static func expand(source: Dictionary) -> Dictionary:
	var result: Dictionary=source.get("floor_layout",{}).duplicate(true)
	var kits: Dictionary=source.get("floor_kits",{})
	var errors: Array=result.get("assembly_errors",[])
	for instance: Dictionary in source.get("floor_assemblies",[]):
		var key := str(instance.get("kit",""))
		var origin: Array=instance.get("origin",[0,0])
		if not kits.has(key) or origin.size()!=2 or not instance.has("prefix"):
			errors.append("Invalid floor assembly: "+key)
			continue
		var kit: Dictionary=kits[key]
		var prefix := str(instance["prefix"])
		var turns := posmod(int(instance.get("quarter_turns",0)),4)
		var offset := Vector2(origin[0],origin[1])
		var lift := float(instance.get("elevation",0.0))
		var ids: Dictionary={}
		for entry: Dictionary in kit.get("surfaces",[]):
			var id := str(entry.get("id",""))
			ids[id]=prefix+id
		for entry: Dictionary in kit.get("walls",[]):
			var id := str(entry.get("id",""))
			ids[id]=prefix+id
		for entry: Dictionary in kit.get("surfaces",[]):
			var surface := entry.duplicate(true)
			surface["id"]=ids[str(entry["id"])]
			var ramp := {"axis":surface.get("axis","x"),"start":surface.get("level",0.0),"end":surface.get("end_level",surface.get("level",0.0))}
			var rect_piece := {"rect":surface["rect"],"ramp":ramp}
			TerrainAssembly.rotate_piece(rect_piece,turns)
			surface["rect"]=translate_rect(rect_piece["rect"],offset)
			surface["level"]=float(ramp["start"])+lift
			if entry.has("end_level"):
				surface["end_level"]=float(ramp["end"])+lift
			if entry.has("axis") or entry.has("end_level"):
				surface["axis"]=ramp["axis"]
			append(result,"surfaces",surface)
		for solid: Array in kit.get("solids",[]):
			var rect_piece := {"rect":[solid[0],solid[2],solid[3],solid[5]]}
			TerrainAssembly.rotate_piece(rect_piece,turns)
			var rect := translate_rect(rect_piece["rect"],offset)
			append(result,"solids",[rect[0],float(solid[1])+lift,rect[1],rect[2],solid[4],rect[3]])
		for field in ["links","climbs"]:
			for entry: Dictionary in kit.get(field,[]):
				var link := entry.duplicate(true)
				link["from"]=endpoint(entry["from"],ids,offset,turns)
				link["to"]=endpoint(entry["to"],ids,offset,turns)
				if link.has("id"):
					link["id"]=prefix+str(link["id"])
				append(result,field,link)
		for entry: Dictionary in kit.get("walls",[]):
			var wall := entry.duplicate(true)
			wall["id"]=ids[str(wall["id"])]
			wall["support"]=ids.get(str(wall["support"]),wall["support"])
			wall["height"]=float(wall["height"])+lift
			TerrainAssembly.rotate_piece(wall,turns)
			wall["rect"]=translate_rect(wall["rect"],offset)
			append(result,"walls",wall)
		for rect: Array in kit.get("null_regions",[]):
			var piece := {"rect":rect.duplicate()}
			TerrainAssembly.rotate_piece(piece,turns)
			append(result,"null_regions",translate_rect(piece["rect"],offset))
	if not errors.is_empty():
		result["assembly_errors"]=errors
	return result


static func append(result: Dictionary,key: String,value: Variant) -> void:
	var entries: Array=result.get(key,[])
	entries.append(value)
	result[key]=entries


static func translate_rect(rect: Array,offset: Vector2) -> Array:
	return [float(rect[0])+offset.x,float(rect[1])+offset.y,rect[2],rect[3]]


static func endpoint(raw: Array,ids: Dictionary,offset: Vector2,turns: int) -> Array:
	var p := Vector2(raw[1],raw[2])
	for i in turns:
		p=Vector2(-p.y,p.x)
	p+=offset
	return [ids.get(str(raw[0]),raw[0]),p.x,p.y]
