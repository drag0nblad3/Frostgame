class_name SoldierArmor
extends RefCounted
const STEEL := Color("849098")
const DARK := Color("353d42")
const BRASS := Color("b49a64")
const LEATHER := Color("594335")


static func body(root: Node3D,plate: bool,heavy: bool,dye: Color) -> void:
	if plate:
		ArmourShapes.cuirass(root,STEEL,heavy)
		for i in 3:
			ArmourShapes.lame(root,0.85-i*0.047,0.40-i*0.025,STEEL.darkened(i*0.07))
	else:
		# Offset rows of overlapping mail links, visible around the surcoat.
		for row in 5:
			for col in 6:
				var x := (col-2.5)*0.072+0.025*(row%2)
				var at := Vector3(x,0.84+row*0.060,-0.205+0.26*x*x)
				MiniatureFactory.sphere(root,at,Vector3(0.065,0.040,0.029),STEEL.darkened(0.20+0.07*((row+col)%2)))
	var tabard := MiniatureFactory.box(root,Vector3(0,0.94,-0.247),Vector3(0.17 if heavy else 0.12,0.35,0.034),dye)
	tabard.rotation.x=-0.04
	MiniatureFactory.box(root,Vector3(0,1.04,-0.273),Vector3(0.06,0.08,0.025),BRASS)


static func head(root: Node3D,id: String,coat: Color,dye: Color) -> void:
	match id:
		"knight":
			var helm := MiniatureFactory.cylinder(root,Vector3(0,1.34,0),0.19,0.20,0.36,STEEL)
			helm.scale.z=0.90
			WeaponSculpt.metal(helm)
			MiniatureFactory.sphere(root,Vector3(0,1.52,0),Vector3(0.39,0.16,0.36),STEEL)
			MiniatureFactory.box(root,Vector3(0,1.38,-0.188),Vector3(0.31,0.052,0.045),DARK)
			WeaponSculpt.metal(MiniatureFactory.box(root,Vector3(0,1.33,-0.22),Vector3(0.045,0.23,0.05),BRASS))
			for x: float in [-0.10,0.10]:
				for y: float in [1.25,1.30]:
					MiniatureFactory.sphere(root,Vector3(x,y,-0.19),Vector3.ONE*0.032,DARK)
			MiniatureFactory.box(root,Vector3(0,1.59,0.025),Vector3(0.09,0.16,0.30),dye)
		"templar","man_at_arms","infantryman","marksman","crossbowman":
			var helmet := MiniatureFactory.sphere(root,Vector3(0,1.44,0.025),Vector3(0.41,0.28,0.38),STEEL)
			WeaponSculpt.metal(helmet)
			var brim := MiniatureFactory.cylinder(root,Vector3(0,1.40,0.02),0.25 if id in ["infantryman","crossbowman"] else 0.205,0.26 if id in ["infantryman","crossbowman"] else 0.21,0.05,STEEL.darkened(0.12))
			WeaponSculpt.metal(brim)
			if id in ["templar","man_at_arms"]:
				WeaponSculpt.metal(MiniatureFactory.box(root,Vector3(0,1.33,-0.19),Vector3(0.048,0.18,0.06),STEEL))
				for side: float in [-1.0,1.0]:
					MiniatureFactory.sphere(root,Vector3(side*0.16,1.30,0.01),Vector3(0.095,0.24,0.23),STEEL.darkened(0.15))
		"thief","ranger","tracker","treasure_hunter":
			ClothSculpt.hood(root,coat.darkened(0.22))
			if id=="thief":
				MiniatureFactory.box(root,Vector3(0,1.24,-0.16),Vector3(0.27,0.10,0.075),coat.darkened(0.24))
		"archer":
			MiniatureFactory.sphere(root,Vector3(0,1.44,0.04),Vector3(0.40,0.25,0.37),LEATHER)
			MiniatureFactory.cylinder(root,Vector3(0,1.40,0),0.21,0.22,0.055,dye)
		"apothecary":
			MiniatureFactory.cylinder(root,Vector3(0,1.46,0),0.17,0.20,0.14,coat)
			for side: float in [-1.0,1.0]:
				WeaponSculpt.metal(MiniatureFactory.sphere(root,Vector3(side*0.072,1.335,-0.18),Vector3(0.09,0.075,0.04),BRASS))
				MiniatureFactory.sphere(root,Vector3(side*0.072,1.335,-0.205),Vector3(0.056,0.05,0.023),Color("779d9d"))
		"barbarian":
			for side: float in [-1.0,1.0]:
				CreatureSculpt.limb(root,Vector3(side*0.13,1.45,0),Vector3(side*0.17,1.17,0.04),0.063,LEATHER,0.52)
			MiniatureFactory.cylinder(root,Vector3(0,1.425,0),0.18,0.19,0.045,dye)
