class_name WizardTailoring
extends RefCounted
## Sculpted, tapered garment volumes with actual folds, split coat panels and seams.
## All surfaces remain batchable with the existing vertex-color pipeline.

static func skirt(root: Node3D,coat: Color,lining: Color,hem: float,width: float,profile: int,split: bool) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const PANELS := 18
	var rows := [0.88,0.72,lerpf(hem,0.72,0.45),hem]
	var points: Array[Vector3] = []
	for j in rows.size():
		var t := float(j)/3.0
		for i in PANELS+1:
			# A visible front opening on short coats.
			var theta := lerpf(0.28 if split else 0.0,TAU-0.28 if split else TAU,float(i)/PANELS)
			var fold := cos(theta*9.0+profile*0.9)*0.032*t
			var radius := lerpf(0.22,width,t)+fold
			var y: float=rows[j]+0.025*sin(theta*3.0+profile)*t
			points.append(Vector3(sin(theta)*radius,y,-cos(theta)*radius*0.78))
	for j in rows.size()-1:
		for i in PANELS:
			var a := j*(PANELS+1)+i
			var b := a+PANELS+1
			for k: int in [a,a+1,b,a+1,b+1,b]:
				st.add_vertex(points[k])
	st.generate_normals()
	var node := MiniatureFactory.mesh(root,st.commit(),Vector3.ZERO,coat)
	var mat: StandardMaterial3D=node.material_override
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	for i in PANELS:
		var a := points[3*(PANELS+1)+i]
		var b := points[3*(PANELS+1)+i+1]
		CreatureSculpt.limb(root,a,b,0.017,coat.darkened(0.20),1.0)
	if split:
		for i in [0,PANELS]:
			for j in 3:
				CreatureSculpt.limb(root,points[j*(PANELS+1)+i],points[(j+1)*(PANELS+1)+i],0.027,lining,1.0)


static func torso(root: Node3D,coat: Color,lining: Color,profile: int,apprentice: bool) -> void:
	var width := (0.25 if apprentice else 0.27)+0.009*float(profile)
	var body := MiniatureFactory.cylinder(root,Vector3(0,0.96,0),width,0.21,0.43,coat)
	body.scale.z=0.73
	MiniatureFactory.sphere(root,Vector3(0,1.105,0.015),Vector3(width*2.05,0.23,0.36),coat)
	for side: float in [-1.0,1.0]:
		var a := Vector3(side*0.19,1.135,-0.14)
		var b := Vector3(side*0.05,0.87,-0.18)
		CreatureSculpt.limb(root,a,b,0.038,lining,0.65)
		for y: float in [0.89,0.96,1.03]:
			MiniatureFactory.sphere(root,Vector3(side*0.045,y,-0.193),Vector3.ONE*0.033,Color("aa9879"))


static func satchel(root: Node3D,profile: int,leather: Color) -> void:
	var side := -1.0 if profile%2==0 else 1.0
	var at := Vector3(side*0.23,0.66,0.08)
	MiniatureFactory.sphere(root,at,Vector3(0.19,0.23,0.17),leather)
	var flap := MiniatureFactory.box(root,at+Vector3(0,0.065,-0.075),Vector3(0.18,0.11,0.05),leather.lightened(0.18))
	flap.rotation.x=-0.16
	WeaponSculpt.metal(MiniatureFactory.sphere(root,at+Vector3(0,0.02,-0.105),Vector3.ONE*0.042,Color("b29a66")))
	CreatureSculpt.limb(root,Vector3(-side*0.15,1.15,0.14),at+Vector3(0,0.12,0.05),0.035,leather,1.0)
