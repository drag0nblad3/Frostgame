class_name InfernalDetails
extends RefCounted
## Demonic tiers have different wing shapes, crests, armor and silhouettes.
const BONE := Color("bca98a")
const IRON := Color("4d4243")


static func decorate(root: Node3D,id: String) -> void:
	var major := id=="major_demon"
	var imp := id=="imp"
	var skin := Color("8b4c43") if imp else (Color("65516d") if major else Color("864d48"))
	if imp or major:
		for side: float in [-1.0,1.0]:
			_wing(root,side,skin,major)
	for side: float in [-1.0,1.0]:
		MiniatureFactory.sphere(root,Vector3(side*0.12,1.05,-0.17),Vector3(0.27,0.26,0.15),skin)
		if major:
			for i in 3:
				var at := Vector3(side*(0.20+i*0.045),1.40+i*0.12,0.09)
				CreatureSculpt.limb(root,at,at+Vector3(side*0.09,0.16,0.04),0.055,BONE,0.02)
		elif not imp:
			for i in 4:
				var at := Vector3(side*0.21,0.73+i*0.11,0.17)
				CreatureSculpt.limb(root,at,at+Vector3(side*0.12,0.09,0.06),0.05,IRON,0.03)
		else:
			CreatureSculpt.limb(root,Vector3(side*0.17,1.35,0),Vector3(side*0.34,1.43,0.035),0.067,skin,0.02)
	if major:
		for i in 3:
			WeaponSculpt.metal(MiniatureFactory.box(root,Vector3(0,0.80-i*0.075,-0.20),Vector3(0.43-i*0.05,0.07,0.07),IRON))
		for i in 5:
			var at := Vector3(0,0.77+i*0.13,0.25)
			CreatureSculpt.limb(root,at,at+Vector3(0,0.11,0.18),0.07,BONE,0.04)


static func _wing(root: Node3D,side: float,skin: Color,major: bool) -> void:
	var reach := 0.67 if major else 0.62
	var a := Vector3(side*0.18,1.11,0.19)
	var b := Vector3(side*0.39,1.48 if major else 1.40,0.27)
	var c := Vector3(side*reach,1.57 if major else 1.44,0.34)
	var d := Vector3(side*(reach-0.08),0.96,0.38)
	var e := Vector3(side*0.40,1.10,0.35)
	var f := Vector3(side*0.27,0.82,0.23)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p: Vector3 in [a,b,c,a,c,d,a,d,e,a,e,f]:
		st.add_vertex(p)
	st.generate_normals()
	var node := MiniatureFactory.mesh(root,st.commit(),Vector3.ZERO,skin.darkened(0.23))
	var mat: StandardMaterial3D=node.material_override
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	for pair: Array in [[a,b],[b,c],[a,d],[a,e],[a,f]]:
		CreatureSculpt.limb(root,pair[0],pair[1],0.033,skin,0.45)


static func undead(root: Node3D,ghoul: bool) -> void:
	var cloth := Color("5c5146")
	if ghoul:
		for i in 4:
			for side: float in [-1.0,1.0]:
				var a := Vector3(side*0.07,0.83+i*0.073,-0.25)
				CreatureSculpt.limb(root,a,a+Vector3(side*0.10,0.027,0.06),0.026,Color("788174"),0.55)
		for side: float in [-1.0,1.0]:
			CreatureSculpt.limb(root,Vector3(side*0.14,1.19,-0.37),Vector3(side*0.13,1.06,-0.43),0.034,BONE,0.03)
	else:
		WizardTailoring.skirt(root,cloth,cloth.darkened(0.2),0.35,0.26,1,true)
		for i in 5:
			var at := Vector3((i-2)*0.074,0.43+0.035*(i%2),-0.20)
			CreatureSculpt.limb(root,at,at+Vector3(0.025,-0.16,0.02),0.031,cloth.darkened(0.12),0.04)
		for side: float in [-1.0,1.0]:
			MiniatureFactory.box(root,Vector3(side*0.12,0.97,-0.25),Vector3(0.065,0.22,0.04),cloth.lightened(0.20))
