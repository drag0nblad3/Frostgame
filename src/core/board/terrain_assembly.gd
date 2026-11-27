class_name TerrainAssembly
extends RefCounted
## Expand reusable rectangular architecture into the canonical terrain format.
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
	result.append_array(source.get("pieces",[]))
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
