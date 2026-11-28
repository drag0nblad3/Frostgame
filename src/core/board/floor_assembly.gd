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
			if id.is_empty() or ids.has(id):
				errors.append("Missing or duplicate local floor ID in "+key)
			ids[id]=prefix+id
		# Explicit static solids are rendered by the floor artwork. Dynamic walls
		# require a corresponding TerrainPiece and remain in BoardLoader.
		for entry: Dictionary in kit.get("surfaces",[]):
			if not entry.has("id") or entry.get("rect",[]).size()!=4:
				errors.append("Malformed floor surface in "+key)
				continue
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
		var volumes: Array=kit.get("solids",[]).duplicate(true)
		for wall: Dictionary in kit.get("aperture_walls",[]):
			volumes.append_array(aperture_volumes(wall,errors))
		for solid: Array in volumes:
			if solid.size()!=6:
				errors.append("Malformed solid in "+key)
				continue
			var rect_piece := {"rect":[solid[0],solid[2],solid[3],solid[5]]}
			TerrainAssembly.rotate_piece(rect_piece,turns)
			var rect := translate_rect(rect_piece["rect"],offset)
			append(result,"solids",[rect[0],float(solid[1])+lift,rect[1],rect[2],solid[4],rect[3]])
		for field in ["links","climbs"]:
			for entry: Dictionary in kit.get(field,[]):
				if entry.get("from",[]).size()!=3 or entry.get("to",[]).size()!=3:
					errors.append("Malformed floor connection in "+key)
					continue
				var link := entry.duplicate(true)
				link["from"]=endpoint(entry["from"],ids,offset,turns)
				link["to"]=endpoint(entry["to"],ids,offset,turns)
				if link.has("id"):
					link["id"]=prefix+str(link["id"])
				append(result,field,link)
		if kit.has("walls"):
			errors.append("Use static solids rather than dynamic walls in floor kit: "+key)
		for rect: Array in kit.get("null_regions",[]):
			if rect.size()!=4:
				errors.append("Malformed null region in "+key)
				continue
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


## A wall is partitioned into actual solid volumes, never a painted aperture.
## Openings are [start, end, sill, head], measured along the local wall axis
## and above its base. Adjacent opening strips can form a stepped arch.
static func aperture_volumes(wall: Dictionary,errors: Array) -> Array:
	var result: Array=[]
	var r: Array=wall.get("rect",[])
	var height:=float(wall.get("height",0.0))
	var base:=float(wall.get("base",0.0))
	var axis_y:=str(wall.get("axis","x"))=="y"
	if r.size()!=4 or height<=0.0 or float(r[2])<=0.0 or float(r[3])<=0.0:
		errors.append("Invalid aperture wall")
		return result
	var length:=float(r[3] if axis_y else r[2])
	var openings: Array=wall.get("openings",[]).duplicate(true)
	for opening in openings:
		if not opening is Array or opening.size()!=4:
			errors.append("Malformed wall aperture")
			return []
	openings.sort_custom(func(a: Array,b: Array) -> bool: return float(a[0])<float(b[0]))
	var cursor:=0.0
	for opening: Array in openings:
		var start:=float(opening[0])
		var end:=float(opening[1])
		var sill:=float(opening[2])
		var head:=float(opening[3])
		if start<cursor-0.0001 or end<=start or end>length+0.0001 or sill<0.0 or head<=sill or head>height+0.0001:
			errors.append("Invalid or overlapping wall aperture")
			return []
		_wall_strip(result,r,axis_y,cursor,start,base,height)
		_wall_strip(result,r,axis_y,start,end,base,sill)
		_wall_strip(result,r,axis_y,start,end,base+head,height-head)
		cursor=end
	_wall_strip(result,r,axis_y,cursor,length,base,height)
	return result


static func _wall_strip(out: Array,r: Array,axis_y: bool,start: float,end: float,base: float,height: float) -> void:
	if end-start<=0.0001 or height<=0.0001:
		return
	out.append([float(r[0])+(0.0 if axis_y else start),base,float(r[1])+(start if axis_y else 0.0),float(r[2]) if axis_y else end-start,height,end-start if axis_y else float(r[3])])
