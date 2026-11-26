class_name RuinedMesh
extends RefCounted
## Broken upper masonry profiles; the logical rectangle and height remain fixed.
## Only non-walkable ruins and low walls use this decorative silhouette.


static func build(size: Vector2, height: float, seed: int) -> ArrayMesh:
	var outline: Array[Vector2] = []
	var half := size*0.5
	var corners: Array[Vector2] = [Vector2(-half.x,-half.y),Vector2(half.x,-half.y),Vector2(half.x,half.y),Vector2(-half.x,half.y)]
	for edge in 4:
		var a := corners[edge]
		var b := corners[(edge+1)%4]
		var steps := maxi(1,ceili(a.distance_to(b)/0.55))
		for i in steps:
			outline.append(a.lerp(b,float(i)/steps))
	var top: Array[Vector3] = []
	var bottom: Array[Vector3] = []
	for i in outline.size():
		var p := outline[i]
		var chip := 0.0 if i%5==0 else float(posmod(i*31+seed*7,11))/10.0*minf(height*0.12,0.24)
		top.append(Vector3(p.x,height*0.5-chip,p.y))
		bottom.append(Vector3(p.x,-height*0.5,p.y))
	var surf := SurfaceTool.new()
	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	surf.set_smooth_group(-1)
	var center := Vector3(0,height*0.5,0)
	for i in outline.size():
		var j := (i+1)%outline.size()
		for p: Vector3 in [bottom[i],bottom[j],top[j],bottom[i],top[j],top[i],center,top[i],top[j]]:
			surf.add_vertex(p)
	surf.generate_normals()
	return surf.commit()
