class_name TerrainAssembly
extends RefCounted
## Expand reusable wall assemblies into the canonical terrain format.
## Shared ruin kits occupy normalized footprints; missing walls are real gaps.
const RUIN_KITS := "res://data/ruin_kits.json"
## Instances translate or rotate in exact quarter turns around their local origin.


static func pieces(source: Dictionary) -> Array:
	var result: Array=[]
	var kits: Dictionary=source.get("kits",{})
	for instance: Dictionary in source.get("assemblies",[]):
		var origin: Array=instance.get("origin",[0,0])
		if origin.size()!=2:
			continue
		for entry: Dictionary in kits.get(str(instance.get("kit","")),[]):
			var piece := entry.duplicate(true)
			var rect: Array=piece.get("rect",[])
			if rect.size()!=4:
				continue
			var turns := posmod(int(instance.get("quarter_turns",0)),4)
			if turns!=0:
				rotate_piece(piece,turns)
			rect=piece["rect"]
			rect[0]+=origin[0]
			rect[1]+=origin[1]
			result.append(piece)
	# Keep ordinary pieces in authored order. A ruin entry expands in place,
	# so checkpoints still store ordinary terrain kinds and rectangles.
	var catalog: Dictionary = {}
	for entry: Dictionary in source.get("pieces",[]):
		if not entry.has("ruin_kit"):
			result.append(entry)
			continue
		if catalog.is_empty():
			catalog=JsonFile.read(RUIN_KITS)
		result.append_array(expand_ruin(entry,catalog))
	return result


static func expand_ruin(entry: Dictionary,catalog: Dictionary) -> Array:
	var result: Array=[]
	var key:=str(entry.get("ruin_kit",""))
	var footprint: Array=entry.get("rect",[])
	if not catalog.has(key) or footprint.size()!=4 or float(footprint[2])<=0.0 or float(footprint[3])<=0.0:
		push_error("Invalid ruin footprint or kit: "+key)
		return result
	var turns:=posmod(int(entry.get("quarter_turns",0)),4)
	# Rotate around the unit square centre, then fit to the authored footprint.
	for local: Dictionary in catalog[key]:
		var piece:=local.duplicate(true)
		var r: Array=piece["rect"]
		for i in turns:
			r=[1.0-float(r[1])-float(r[3]),r[0],r[3],r[2]]
		piece["rect"]=[float(footprint[0])+float(r[0])*float(footprint[2]),float(footprint[1])+float(r[1])*float(footprint[3]),float(r[2])*float(footprint[2]),float(r[3])*float(footprint[3])]
		result.append(piece)
	return result


static func rotate_piece(piece: Dictionary,turns: int) -> void:
	var rect: Array=piece["rect"]
	var x := float(rect[0])
	var y := float(rect[1])
	var w := float(rect[2])
	var h := float(rect[3])
	var directions := ["north","east","south","west"]
	for i in turns:
		var next_x := -y-h
		y=x
		x=next_x
		var next_w := h
		h=w
		w=next_w
		if piece.has("entrance"):
			var facing := directions.find(piece["entrance"])
			if facing>=0:
				piece["entrance"]=directions[(facing+1)%4]
		var ramp: Dictionary=piece.get("ramp",{})
		if not ramp.is_empty():
			if ramp.get("axis","x")=="y":
				var start := float(ramp.get("start",0.0))
				ramp["start"]=ramp.get("end",0.0)
				ramp["end"]=start
				ramp["axis"]="x"
			else:
				ramp["axis"]="y"
	piece["rect"]=[x,y,w,h]
