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
			for side: float in [-1.0,1.0]:
				var crest := MiniatureFactory.cylinder(root,Vector3(side*0.20,1.51,0.04),0.012,0.073,0.30,IVORY)
				crest.rotation.z=-side*0.48
				MiniatureFactory.box(root,Vector3(side*0.16,0.74,-0.24),Vector3(0.16,0.21,0.08),BRONZE if id=="hrut_warrior" else DARK)
				CreatureSculpt.eye(root,Vector3(side*0.09,1.38,-0.20),Color("ffae50"))
			if id=="hrut_longhammer":
				# A broad twin-headed hammer rather than a sword with a cap.
				CreatureSculpt.limb(root,Vector3(0.38,0.68,-0.25),Vector3(0.46,1.58,-0.38),0.055,BRONZE,1.0)
				MiniatureFactory.box(root,Vector3(0.46,1.58,-0.38),Vector3(0.62,0.26,0.28),DARK)
				for side: float in [-1.0,1.0]:
					MiniatureFactory.box(root,Vector3(0.46+side*0.31,1.58,-0.38),Vector3(0.12,0.31,0.32),BRONZE)
			else:
				MiniatureFactory.weapon(root,f)
			if id=="hrut_darter":
				# Bolt case and narrow orange shoulder flash distinguish the ground shooter.
				MiniatureFactory.cylinder(root,Vector3(-0.25,1.03,0.29),0.095,0.10,0.61,BRONZE).rotation.z=-0.25
				for y: float in [1.22,1.33,1.44]:
					MiniatureFactory.box(root,Vector3(-0.25,y,0.29),Vector3(0.19,0.04,0.14),IVORY)
			if id=="hrut_longhammer":
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
				for side: float in [-1.0,1.0]:
					CreatureSculpt.limb(root,Vector3(side*0.16,1.35,0.18),Vector3(side*0.71,1.91,0.22),0.09,BRONZE,0.1)
					MiniatureFactory.sphere(root,Vector3(side*0.50,1.46,0.29),Vector3(0.52,0.81,0.10),RED).rotation.z=-side*0.62
				root.position.y=0.17
			else:
				# Ring-shaped crown and oversized key distinguish the finale objective.
				var halo := TorusMesh.new()
				halo.inner_radius=0.18
				halo.outer_radius=0.25
				halo.rings=16
				halo.ring_segments=6
				MiniatureFactory.mesh(root,halo,Vector3(0,1.76,0.03),BRONZE).rotation.x=PI*0.5
				for y: float in [0.41,0.57]:
					MiniatureFactory.box(root,Vector3(0.56,y,-0.19),Vector3(0.26,0.08,0.08),BRONZE)
		"blood_marked_berserker":
			MonsterSculpt.undead(root,false)
			MiniatureFactory.box(root,Vector3(0.07,1.31,-0.44),Vector3(0.08,0.20,0.03),RED).rotation.z=-0.24
			for side: float in [-1.0,1.0]:
				MiniatureFactory.sphere(root,Vector3(side*0.28,1.04,0),Vector3(0.26,0.26,0.30),Color("63564c"))
				MiniatureFactory.box(root,Vector3(side*0.12,0.64,-0.20),Vector3(0.11,0.27,0.055),RED).rotation.z=side*0.20
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
			for side: float in [-1.0,1.0]:
				CreatureSculpt.limb(root,Vector3(side*0.18,1.40,-0.08),Vector3(side*0.53,1.62,-0.31),0.10,IVORY,0.03)
		"mindshrike":
			MiniatureFactory.sphere(root,Vector3(0,1.12,0),Vector3(0.69,0.48,0.81),Color("66898d"))
			MiniatureFactory.sphere(root,Vector3(0,1.22,0.12),Vector3(0.58,0.32,0.51),Color("31495a"))
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
			for y: float in [0.81,0.98,1.15]:
				MiniatureFactory.box(root,Vector3(0,y,-0.14),Vector3(0.25,0.025,0.025),Color("555c6a"))
			MiniatureFactory.box(root,Vector3(0,1.45,-0.124),Vector3(0.10,0.026,0.025),Color("262c39"))
		"kalamon_ryce":
			MiniatureFactory.cylinder(root,Vector3(0,0.59,0),0.19,0.29,0.88,Color("5c6e69"))
			MiniatureFactory.sphere(root,Vector3(0,1.03,0),Vector3(0.41,0.41,0.31),Color("677c72"))
			MiniatureFactory.sphere(root,Vector3(0,1.36,-0.08),Vector3(0.30,0.34,0.29),Color("c4ad91"))
			MiniatureFactory.sphere(root,Vector3(0,1.41,0.04),Vector3(0.39,0.40,0.33),Color("c5c4b7"))
			for side: float in [-1.0,1.0]:
				CreatureSculpt.limb(root,Vector3(side*0.18,1.15,0),Vector3(side*0.36,0.76,-0.20),0.092,Color("5c6e69"))
				MiniatureFactory.sphere(root,Vector3(side*0.36,0.76,-0.20),Vector3.ONE*0.13,Color("c4ad91"))
				MiniatureFactory.box(root,Vector3(side*0.13,0.12,-0.04),Vector3(0.19,0.18,0.31),Color("544c42"))
				CreatureSculpt.eye(root,Vector3(side*0.065,1.37,-0.225),Color("ded8b5"))
			MiniatureFactory.box(root,Vector3(0,0.85,-0.18),Vector3(0.09,0.20,0.045),BRONZE)
		_:
			return false
	return true
