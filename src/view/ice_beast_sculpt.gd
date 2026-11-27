class_name IceBeastSculpt
extends RefCounted
const ICE := Color("a9c9d4")
const DARK := Color("354c59")


static func spider(root: Node3D) -> void:
	MiniatureFactory.sphere(root,Vector3(0,0.48,0.17),Vector3(0.67,0.57,0.76),ICE.darkened(0.18))
	MiniatureFactory.sphere(root,Vector3(0,0.40,-0.27),Vector3(0.43,0.37,0.45),DARK)
	for i in 5:
		var at := Vector3(0,0.70,0.40-i*0.14)
		CreatureSculpt.limb(root,at,at+Vector3(0,0.15,0.035),0.09,ICE.lightened(0.16),0.02)
	for side: float in [-1.0,1.0]:
		for i in 4:
			var z := -0.31+i*0.18
			var a := Vector3(side*0.19,0.43,z)
			var b := Vector3(side*(0.46+0.035*i),0.66,z*1.4)
			var c := Vector3(side*0.67,0.28,z*1.65)
			var d := Vector3(side*0.77,0.04,z*1.8)
			var pivot := MiniaturePose.leg(root,i+(4 if side>0 else 0),a)
			var first := root.get_child_count()
			CreatureSculpt.limb(root,a,b,0.065,ICE,0.8)
			MiniatureFactory.sphere(root,b,Vector3.ONE*0.12,DARK)
			CreatureSculpt.limb(root,b,c,0.048,DARK.lightened(0.12),0.8)
			CreatureSculpt.limb(root,c,d,0.037,ICE,0.03)
			MiniaturePose.attach(root,pivot,first)
		for i in 3:
			CreatureSculpt.eye(root,Vector3(side*(0.055+i*0.055),0.43+0.035*(i%2),-0.48),Color("b4e8f2"))
		CreatureSculpt.limb(root,Vector3(side*0.13,0.33,-0.46),Vector3(side*0.09,0.17,-0.61),0.06,ICE.lightened(0.2),0.04)


static func toad(root: Node3D) -> void:
	var skin := Color("597d7e")
	MiniatureFactory.sphere(root,Vector3(0,0.35,0.10),Vector3(0.79,0.57,0.78),skin)
	MiniatureFactory.sphere(root,Vector3(0,0.27,-0.14),Vector3(0.64,0.38,0.63),Color("a1ae9d"))
	MiniatureFactory.sphere(root,Vector3(0,0.38,-0.38),Vector3(0.73,0.34,0.43),skin.lightened(0.1))
	for side: float in [-1.0,1.0]:
		var eye := Vector3(side*0.28,0.55,-0.35)
		MiniatureFactory.sphere(root,eye,Vector3.ONE*0.23,skin)
		MiniatureFactory.sphere(root,eye+Vector3(0,0.025,-0.09),Vector3(0.16,0.13,0.08),Color("d0b766"))
		MiniatureFactory.box(root,eye+Vector3(0,0.025,-0.137),Vector3(0.11,0.033,0.02),DARK)
		var hind := MiniaturePose.leg(root,1 if side<0 else 3,Vector3(side*0.25,0.32,0.20))
		var first := root.get_child_count()
		MiniatureFactory.sphere(root,Vector3(side*0.36,0.23,0.25),Vector3(0.36,0.34,0.53),skin.darkened(0.12))
		MiniaturePose.attach(root,hind,first)
		var fore := MiniaturePose.leg(root,0 if side<0 else 2,Vector3(side*0.30,0.37,-0.24))
		first=root.get_child_count()
		CreatureSculpt.limb(root,Vector3(side*0.30,0.37,-0.24),Vector3(side*0.39,0.10,-0.35),0.105,skin,0.70)
		for i in 4:
			var a := Vector3(side*0.38+(i-1.5)*0.045,0.07,-0.33)
			CreatureSculpt.limb(root,a,a+Vector3((i-1.5)*0.035,-0.025,-0.16),0.025,skin.lightened(0.1),0.65)
		MiniaturePose.attach(root,fore,first)
		for i in 6:
			var at := Vector3(side*(0.16+0.11*(i%2)),0.56-0.055*(i%2),0.38-i*0.12)
			MiniatureFactory.sphere(root,at,Vector3.ONE*(0.07+0.02*(i%3)),ICE.darkened(0.18))
	for i in 4:
		var a := Vector3(-0.28+i*0.14,0.31,-0.55)
		CreatureSculpt.limb(root,a,a+Vector3(0.14,0,-0.015),0.016,DARK,1.0)
