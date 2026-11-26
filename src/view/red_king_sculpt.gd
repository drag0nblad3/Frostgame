class_name RedKingSculpt
extends RefCounted
## Original compact meshes for the invasion bestiary.
const DARK := Color("252432")
const RED := Color("a92c36")
const BRONZE := Color("b38952")
const IVORY := Color("d9d1b7")


static func create(root: Node3D,f: Figure) -> bool:
	var id := f.def.id
	match id:
		"hrut_warrior","hrut_stinger","hrut_longhammer","hrut_darter":
			MonsterSculpt.demon(root,"minor_demon")
			for side: float in [-1.0,1.0]:
				MiniatureFactory.sphere(root,Vector3(side*0.31,1.07,0),Vector3(0.34,0.30,0.38),DARK)
				MiniatureFactory.box(root,Vector3(side*0.18,0.47,-0.12),Vector3(0.22,0.32,0.18),DARK)
				if id=="hrut_stinger":
					CreatureSculpt.limb(root,Vector3(side*0.12,1.0,0.16),Vector3(side*0.66,1.63,0.24),0.10,RED,0.25)
					MiniatureFactory.sphere(root,Vector3(side*0.47,1.23,0.25),Vector3(0.5,0.78,0.10),RED.darkened(0.35)).rotation.z=-side*0.63
			MiniatureFactory.sphere(root,Vector3(0,0.95,-0.20),Vector3(0.48,0.48,0.16),DARK)
			MiniatureFactory.box(root,Vector3(0,0.94,-0.29),Vector3(0.09,0.30,0.035),BRONZE)
			MiniatureFactory.sphere(root,Vector3(0,1.37,-0.03),Vector3(0.36,0.31,0.36),DARK)
			MiniatureFactory.weapon(root,f)
			if id=="hrut_longhammer":
				MiniatureFactory.box(root,Vector3(0.45,1.32,-0.38),Vector3(0.42,0.21,0.24),BRONZE)
				root.scale=Vector3(1.18,1.28,1.18)
		"herald_of_the_red_king","red_king_herald","key_master","red_king_key_master":
			var herald := id.contains("herald")
			MiniatureFactory.cylinder(root,Vector3(0,0.66,0),0.21,0.39,1.02,RED.darkened(0.35))
			MiniatureFactory.sphere(root,Vector3(0,1.17,0),Vector3(0.49,0.43,0.35),DARK)
			MiniatureFactory.sphere(root,Vector3(0,1.52,0),Vector3(0.39,0.42,0.36),BRONZE)
			CreatureSculpt.eye(root,Vector3(0,1.55,-0.20),Color("ffcf68"))
			for side: float in [-1.0,1.0]:
				CreatureSculpt.limb(root,Vector3(side*0.21,1.28,0),Vector3(side*0.41,0.99,-0.17),0.12,RED)
				CreatureSculpt.limb(root,Vector3(side*0.15,1.50,-0.16),Vector3(side*0.28,1.28,-0.22),0.065,IVORY,0.1)
				if herald or side>0:
					MiniatureFactory.cylinder(root,Vector3(side*0.43,0.94,-0.19),0.035,0.045,1.57,BRONZE)
					MiniatureFactory.sphere(root,Vector3(side*0.43,1.77,-0.19),Vector3.ONE*0.19,Color("f69848"))
			if herald:
				root.position.y=0.17
		"blood_marked_berserker":
			MonsterSculpt.undead(root,false)
			MiniatureFactory.box(root,Vector3(0.07,1.31,-0.44),Vector3(0.08,0.20,0.03),RED).rotation.z=-0.24
			MiniatureFactory.weapon(root,f)
		"burning_man":
			MonsterSculpt.undead(root,true)
			for i in 9:
				var a := TAU*float(i)/9.0
				var y := 0.32+float(i%3)*0.38
				var flame := MiniatureFactory.cylinder(root,Vector3(cos(a)*0.27,y,sin(a)*0.25),0.015,0.14,0.47,Color("f26324") if i%2==0 else Color("ffbf45"))
				flame.rotation.z=sin(a)*0.32
		"foulhorn":
			MonsterSculpt.demon(root,"minor_demon")
			for side: float in [-1.0,1.0]:
				CreatureSculpt.limb(root,Vector3(side*0.23,0.94,0.12),Vector3(side*0.53,0.69,-0.12),0.12,DARK)
				CreatureSculpt.limb(root,Vector3(side*0.53,0.69,-0.12),Vector3(side*0.59,0.35,-0.46),0.13,IVORY,0.0)
		"mindshrike":
			MiniatureFactory.sphere(root,Vector3(0,1.12,0),Vector3(0.69,0.48,0.81),Color("66898d"))
			for i in 7:
				var a := TAU*float(i)/7.0
				var p := Vector3(cos(a)*0.23,0.97,sin(a)*0.26)
				var q := p+Vector3(cos(a)*0.16,-0.39,sin(a)*0.18)
				CreatureSculpt.limb(root,p,q,0.07,Color("89b8bb"),0.4)
				CreatureSculpt.limb(root,q,q+Vector3(0.04,-0.24,-0.06),0.045,Color("b3d1cf"),0.0)
			MiniatureFactory.sphere(root,Vector3(0,1.08,-0.38),Vector3(0.33,0.20,0.10),DARK)
			for x: float in [-0.18,0.18]:
				CreatureSculpt.eye(root,Vector3(x,1.20,-0.30),Color("f5d47a"))
		"nullman":
			var ash := Color("acb3bd")
			MiniatureFactory.sphere(root,Vector3(0,1.0,0),Vector3(0.40,0.63,0.25),ash)
			MiniatureFactory.sphere(root,Vector3(0,1.44,0),Vector3(0.26,0.34,0.24),ash.lightened(0.17))
			for side: float in [-1.0,1.0]:
				CreatureSculpt.limb(root,Vector3(side*0.17,1.22,0),Vector3(side*0.27,0.65,-0.04),0.085,ash)
				CreatureSculpt.limb(root,Vector3(side*0.11,0.73,0),Vector3(side*0.15,0.12,0),0.105,ash)
		_:
			return false
	return true
