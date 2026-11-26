class_name RangedSculpt
extends RefCounted
const WOOD := Color("74533a")
const STEEL := Color("8b9597")
const STRING := Color("c7bca0")


static func bow(root: Node3D) -> void:
	var points: Array[Vector3]=[Vector3(-0.17,0.21,-0.09),Vector3(-0.30,0.37,-0.09),Vector3(-0.39,0.57,-0.09),Vector3(-0.38,0.76,-0.09),Vector3(-0.39,0.96,-0.09),Vector3(-0.30,1.16,-0.09),Vector3(-0.17,1.32,-0.09)]
	for i in range(1,points.size()):
		CreatureSculpt.limb(root,points[i-1],points[i],0.032 if i in [1,6] else 0.044,WOOD,0.83)
	CreatureSculpt.limb(root,points[0],points[-1],0.009,STRING,1.0)
	CreatureSculpt.limb(root,Vector3(-0.38,0.67,-0.09),Vector3(-0.38,0.85,-0.09),0.047,WOOD.darkened(0.35),1.0)


static func crossbow(root: Node3D) -> void:
	MiniatureFactory.box(root,Vector3(-0.38,0.84,-0.26),Vector3(0.12,0.13,0.62),WOOD)
	MiniatureFactory.box(root,Vector3(-0.38,0.88,-0.20),Vector3(0.065,0.045,0.49),STEEL)
	var grip := MiniatureFactory.box(root,Vector3(-0.38,0.76,-0.09),Vector3(0.085,0.17,0.095),WOOD.darkened(0.22))
	grip.rotation.x=-0.22
	var center := Vector3(-0.38,0.88,-0.47)
	for side: float in [-1.0,1.0]:
		var elbow := center+Vector3(side*0.23,0,0.065)
		var tip := center+Vector3(side*0.34,0,0.19)
		WeaponSculpt.metal(CreatureSculpt.limb(root,center,elbow,0.033,STEEL,0.85))
		WeaponSculpt.metal(CreatureSculpt.limb(root,elbow,tip,0.026,STEEL,0.48))
		CreatureSculpt.limb(root,tip,center+Vector3(0,0,0.24),0.009,STRING,1.0)
	CreatureSculpt.limb(root,center+Vector3(0,0.04,0.26),center+Vector3(0,0.04,-0.20),0.015,WOOD.lightened(0.20),1.0)
	WeaponSculpt.metal(CreatureSculpt.limb(root,center+Vector3(0,0.04,-0.17),center+Vector3(0,0.04,-0.25),0.029,STEEL,0.02))
