class_name SupernaturalDetails
extends RefCounted
## Large, category-specific details; no new gameplay equipment.
const BONE := Color("d5c8ab")
const ICE := Color("b7d3dc")
const DARK := Color("30353c")


static func decorate(root: Node3D,id: String) -> void:
	match id:
		"skeleton","armoured_skeleton","skeleton_archer":
			for side: float in [-1.0,1.0]:
				var a := Vector3(side*0.17,1.12,0.035)
				CreatureSculpt.limb(root,Vector3(0,1.17,0.03),a,0.035,BONE,0.85)
				MiniatureFactory.sphere(root,Vector3(side*0.14,0.61,-0.055),Vector3(0.14,0.13,0.08),BONE.darkened(0.16))
		"animated_skull":
			_crack(root,Vector3(-0.10,1.15,-0.19),0.13)
		"ghoul","zombie":
			for side: float in [-1.0,1.0]:
				var y := 1.16 if id=="ghoul" else 1.30
				MiniatureFactory.sphere(root,Vector3(side*0.105,y+0.07,-0.37),Vector3(0.13,0.05,0.07),Color("606e5d"))
		"imp","minor_demon","major_demon":
			for side: float in [-1.0,1.0]:
				CreatureSculpt.limb(root,Vector3(side*0.15,1.39,-0.14),Vector3(side*0.18,1.40,-0.24),0.048,DARK,0.35)
				for i in 2:
					var at := Vector3(side*0.19,0.66+i*0.10,0.18)
					CreatureSculpt.limb(root,at,at+Vector3(side*0.12,0.10,0.07),0.047,BONE.darkened(0.24),0.03)
		"wraith":
			for side: float in [-1.0,1.0]:
				CreatureSculpt.limb(root,Vector3(side*0.13,0.69,-0.16),Vector3(side*0.25,0.31,-0.20),0.028,Color("93b6c1"),0.18)
		"genie":
			for side: float in [-1.0,1.0]:
				TabletopKit.rivet(root,Vector3(side*0.20,1.34,-0.08),Color("c6a664"))
		"white_gorilla","werewolf","snow_troll","frost_giant":
			for side: float in [-1.0,1.0]:
				for i in 3:
					var at := Vector3(side*0.23,1.12-i*0.10,0.20)
					CreatureSculpt.limb(root,at,at+Vector3(side*0.09,-0.10,0.05),0.055,ICE.darkened(0.19 if id=="werewolf" else 0.02),0.03)
		"ice_spider":
			for side: float in [-1.0,1.0]:
				for i in 3:
					var a := Vector3(side*0.22,0.58,0.34-i*0.15)
					CreatureSculpt.limb(root,a,a+Vector3(side*0.10,0.11,0.03),0.062,ICE,0.02)
		"ice_toad":
			for side: float in [-1.0,1.0]:
				MiniatureFactory.sphere(root,Vector3(side*0.22,0.38,-0.54),Vector3(0.15,0.055,0.055),Color("6d938e"))
		"giant_worm":
			for i in 4:
				var t := float(i)/3.0
				var a := Vector3(sin(t*PI)*0.32,0.28+t*1.35,0.42-t*t*0.50)
				CreatureSculpt.limb(root,a,a+Vector3(0,0.10,0.12),0.065,Color("9b8b72"),0.12)


static func _crack(root: Node3D,a: Vector3,length: float) -> void:
	var b := a+Vector3(0.035,-length*0.5,-0.01)
	CreatureSculpt.limb(root,a,b,0.012,DARK,1.0)
	CreatureSculpt.limb(root,b,b+Vector3(-0.035,-length*0.5,-0.01),0.010,DARK,0.3)
