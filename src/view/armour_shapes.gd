class_name ArmourShapes
extends RefCounted
## Shaped armour shells, curved waist plates and a bevelled heater shield.
## Standard materials remain compatible with the miniature batching pipeline.


static func cuirass(root: Node3D,color: Color,heavy: bool) -> void:
	var cols := 12 if MiniatureFactory.detail(root)>0 else 8
	var widths := [0.18,0.22,0.25 if heavy else 0.23,0.22,0.13]
	var heights := [0.80,0.88,0.99,1.10,1.16]
	var points: Array[Vector3]=[]
	for j in heights.size():
		for i in cols+1:
			var u := float(i)/cols*2.0-1.0
			var z := -0.115-0.132*sqrt(maxf(0.0,1-u*u))
			z-=0.016*(1.0-absf(u))
			points.append(Vector3(float(widths[j])*u,float(heights[j])-0.025*absf(u),z))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in heights.size()-1:
		for i in cols:
			var a := j*(cols+1)+i
			var b := a+cols+1
			for k in [a,b,a+1,a+1,b,b+1]:
				st.add_vertex(points[k])
	st.generate_normals()
	var breast := MiniatureFactory.mesh(root,st.commit(),Vector3.ZERO,color)
	WeaponSculpt.metal(breast)
	breast.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
	for side: float in [-1.0,1.0]:
		CreatureSculpt.limb(root,Vector3(side*0.20,1.08,-0.13),Vector3(side*0.12,1.16,-0.17),0.023,color.lightened(0.23),1.0)
		for y: float in [0.88,0.94,1.02]:
			WeaponSculpt.metal(MiniatureFactory.sphere(root,Vector3(side*0.19,y,-0.198),Vector3.ONE*0.032,color.lightened(0.21)))


static func lame(root: Node3D,y: float,width: float,color: Color) -> void:
	var count := 8
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in count:
		var a := float(i)/count*2.0-1.0
		var b := float(i+1)/count*2.0-1.0
		var p := Vector3(a*width*0.5,y-0.03,-0.16-0.105*sqrt(maxf(0.0,1.0-a*a)))
		var q := Vector3(b*width*0.5,y-0.03,-0.16-0.105*sqrt(maxf(0.0,1.0-b*b)))
		for at: Vector3 in [p,p+Vector3.UP*0.072,q,q,p+Vector3.UP*0.072,q+Vector3.UP*0.072]:
			st.add_vertex(at)
	st.generate_normals()
	var plate := MiniatureFactory.mesh(root,st.commit(),Vector3.ZERO,color)
	WeaponSculpt.metal(plate)
	plate.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED


static func heater_shield(root: Node3D,center: Vector3) -> void:
	var outline := PackedVector2Array([Vector2(-0.25,0.26),Vector2(0.25,0.26),Vector2(0.25,0.03),Vector2(0.20,-0.12),Vector2(0.10,-0.24),Vector2(0,-0.32),Vector2(-0.10,-0.24),Vector2(-0.20,-0.12),Vector2(-0.25,0.03)])
	_shield_shell(root,center,outline,1.0,0.0,Color("ad9568"),true)
	_shield_shell(root,center,outline,0.84,-0.028,Color("405c73"),false)
	WeaponSculpt.metal(MiniatureFactory.box(root,center+Vector3(0,-0.012,-0.103),Vector3(0.055,0.43,0.020),Color("cbb478")))
	WeaponSculpt.metal(MiniatureFactory.box(root,center+Vector3(0,0.08,-0.098),Vector3(0.32,0.052,0.020),Color("cbb478")))
	for p in outline:
		WeaponSculpt.metal(MiniatureFactory.sphere(root,center+Vector3(p.x*0.92,p.y*0.92,-0.055),Vector3.ONE*0.032,Color("d3c6a3")))


static func _shield_shell(root: Node3D,center: Vector3,outline: PackedVector2Array,scale_factor: float,z: float,color: Color,metallic: bool) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in outline.size():
		var a := outline[i]*scale_factor
		var b := outline[(i+1)%outline.size()]*scale_factor
		var va := Vector3(a.x,a.y,z)
		var vb := Vector3(b.x,b.y,z)
		for p: Vector3 in [Vector3(0,0,z-0.068),va,vb,va,va+Vector3(0,0,0.035),vb,vb,va+Vector3(0,0,0.035),vb+Vector3(0,0,0.035)]:
			st.add_vertex(p)
	st.generate_normals()
	var shape := MiniatureFactory.mesh(root,st.commit(),center,color)
	shape.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
	if metallic:
		WeaponSculpt.metal(shape)
