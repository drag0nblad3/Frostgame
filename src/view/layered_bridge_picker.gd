class_name LayeredBridgePicker
extends RefCounted


static func points(c: GameController,layout: FloorLayout,index: int,first: Variant) -> Dictionary:
	var out := {}
	if index<0 or index>=layout.surfaces.size() or not LayeredBridge.eligible(c):
		return out
	var surface := layout.surfaces[index]
	var offsets: Array[Vector2i]=[Vector2i(12,0),Vector2i(-12,0),Vector2i(0,12),Vector2i(0,-12)]
	if ActiveGear.ready(c.state.active(),TerrainMagic.EXTENDED):
		offsets.append_array([Vector2i(18,0),Vector2i(-18,0),Vector2i(0,18),Vector2i(0,-18)])
	if first!=null:
		for d: Vector2i in offsets:
			var n := Vector3i(first.x+d.x,first.y+d.y,index)
			if not LayeredBridge.proposal(c,first,n,layout).is_empty():
				out[n]=true
		return out
	# First endpoint needs at least one valid second endpoint on another surface.
	for x in range(ceili(surface.rect.position.x/MoveGrid.STEP),floori(surface.rect.end.x/MoveGrid.STEP)+1):
		for y in range(ceili(surface.rect.position.y/MoveGrid.STEP),floori(surface.rect.end.y/MoveGrid.STEP)+1):
			var a := Vector3i(x,y,index)
			if not layout.standable(a):
				continue
			for d: Vector2i in offsets:
				for other in layout.surfaces.size():
					if other==index:
						continue
					var b := Vector3i(x+d.x,y+d.y,other)
					if layout.standable(b) and not LayeredBridge.proposal(c,a,b,layout).is_empty():
						out[a]=true
						break
				if out.has(a):
					break
	return out
