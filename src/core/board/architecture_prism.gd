class_name ArchitecturePrism
extends RefCounted
## Convex extruded profile, with identical physical and visual geometry.
## Profiles may lie in any plane; the extrusion need not be vertical.
var vertices:=PackedVector3Array()
var faces: Array[PackedInt32Array]=[]
var planes: Array[Plane]=[]
var bounds:=AABB()
var axes:=PackedVector3Array()
var minima:=PackedFloat64Array()
var maxima:=PackedFloat64Array()
var valid:=false


static func from_dict(d: Dictionary) -> ArchitecturePrism:
	var result:=ArchitecturePrism.new()
	var raw: Array=d.get("profile",[])
	var e: Array=d.get("extrusion",[])
	if raw.size()<3 or raw.size()>32 or e.size()!=3:
		return result
	var delta:=Vector3(e[0],e[1],e[2])
	if delta.length()<0.001:
		return result
	for p in raw:
		if not p is Array or p.size()!=3:
			return result
		result.vertices.append(Vector3(p[0],p[1],p[2]))
	var n:=raw.size()
	var normal: Vector3=(result.vertices[1]-result.vertices[0]).cross(result.vertices[2]-result.vertices[0]).normalized()
	if absf(normal.dot(delta))<0.001:
		return result
	for p in result.vertices:
		if absf(normal.dot(p-result.vertices[0]))>0.001:
			return result
	for i in n:
		result.vertices.append(result.vertices[i]+delta)
	var bottom:=PackedInt32Array()
	var top:=PackedInt32Array()
	for i in n:
		bottom.append(i)
		top.append(i+n)
	result.faces.append(bottom)
	result.faces.append(top)
	for i in n:
		var j: int=(i+1)%n
		result.faces.append(PackedInt32Array([i,j,j+n,i+n]))
	var center:=Vector3.ZERO
	result.bounds=AABB(result.vertices[0],Vector3.ZERO)
	for p in result.vertices:
		center+=p
		result.bounds=result.bounds.expand(p)
	center/=float(result.vertices.size())
	for i in result.faces.size():
		var face:=result.faces[i]
		var a:=result.vertices[face[0]]
		var b:=result.vertices[face[1]]
		var c:=result.vertices[face[2]]
		var outward: Vector3=(b-a).cross(c-a).normalized()
		if outward.length_squared()<0.5:
			return result
		if outward.dot(center-a)>0.0:
			outward=-outward
			face.reverse()
			result.faces[i]=face
		var plane:=Plane(outward,outward.dot(a))
		# Reject non-convex or incorrectly ordered profiles.
		for p in result.vertices:
			if plane.distance_to(p)>0.001:
				return result
		result.planes.append(plane)
		result._axis(outward)
	# Separating-axis theorem: face normals, box axes and edge cross axes.
	for axis: Vector3 in [Vector3.RIGHT,Vector3.UP,Vector3.BACK]:
		result._axis(axis)
		for i in n:
			result._axis(axis.cross(result.vertices[(i+1)%n]-result.vertices[i]))
		result._axis(axis.cross(delta))
	result.valid=true
	return result


func _axis(raw: Vector3) -> void:
	if raw.length_squared()<0.000001:
		return
	var axis:=raw.normalized()
	for previous in axes:
		if absf(axis.dot(previous))>0.999999:
			return
	var lo:=INF
	var hi:=-INF
	for p in vertices:
		var value:=axis.dot(p)
		lo=minf(lo,value)
		hi=maxf(hi,value)
	axes.append(axis)
	minima.append(lo)
	maxima.append(hi)


func overlaps(box: AABB) -> bool:
	if not bounds.intersects(box):
		return false
	var center:=box.get_center()
	var half:=box.size*0.5
	for i in axes.size():
		var axis:=axes[i]
		var mid:=axis.dot(center)
		var radius:=absf(axis.x)*half.x+absf(axis.y)*half.y+absf(axis.z)*half.z
		if mid+radius<=minima[i]+0.00001 or mid-radius>=maxima[i]-0.00001:
			return false
	return true


func intersects_ray(a: Vector3,b: Vector3) -> bool:
	# Clip segment against all outward-facing halfspaces.
	var lo:=0.0
	var hi:=1.0
	for plane in planes:
		var da:=plane.distance_to(a)
		var db:=plane.distance_to(b)
		if da>0.00001 and db>0.00001:
			return false
		if da<=0.0 and db<=0.0:
			continue
		var denominator:=da-db
		if absf(denominator)<0.000001:
			continue
		var t:=da/denominator
		if da>0.0:
			lo=maxf(lo,t)
		else:
			hi=minf(hi,t)
		if lo>hi:
			return false
	return true


func mesh() -> ArrayMesh:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in faces.size():
		var face:=faces[i]
		for j in range(1,face.size()-1):
			# Godot's front faces use clockwise winding.
			for index in [face[0],face[j+1],face[j]]:
				surface.set_normal(planes[i].normal)
				surface.add_vertex(vertices[index])
	return surface.commit()
