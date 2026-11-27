class_name TerrainAssembly
extends RefCounted
## Expand reusable rectangular architecture into the canonical terrain format.
## Offsets are translations only; preserve author-defined geometry and order.


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
			rect[0]+=origin[0]
			rect[1]+=origin[1]
			result.append(piece)
	result.append_array(source.get("pieces",[]))
	return result
