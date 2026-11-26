class_name EnvironmentProps
extends RefCounted
## Bold scenery forms at tabletop scale, sharing the miniature batching materials.
const WOOD := Color("6c5140")
const IRON := Color("454b4e")
const STONE := Color("839096")
const SNOW := Color("d4dfe2")
const BRASS := Color("a38a54")


static func frost(root: Node3D,at: Vector3,radius: float,seed: int) -> void:
	for i in 3:
		var m := MiniatureFactory.sphere(root,at+Vector3((i-1)*radius*0.28,0,0),Vector3(radius*0.95,0.022,radius*1.05),SNOW.darkened(i*0.035))
		m.rotation.y=seed*0.37+i*0.8


static func paving(root: Node3D,at: Vector3,radius: float,seed: int,tint: Color) -> void:
	for i in 2:
		var m := MiniatureFactory.box(root,at+Vector3((i-0.5)*radius*0.65,0,0),Vector3(radius*0.60,0.024,radius*0.82),tint.lightened(i*0.10))
		m.rotation.y=0.42*sin(seed+i)


static func ruin_debris(root: Node3D,at: Vector3,scenario: String,seed: int,width: float) -> void:
	# Never taller than the existing 0.4-inch rubble terrain.
	var p := at+Vector3(0,0.16,0)
	match scenario:
		"underground_library":
			for i in 3:
				var book := MiniatureFactory.box(root,at+Vector3(0,0.045+i*0.085,0),Vector3(width*0.76,0.08,width*0.55),SiteArt.BOOKS[posmod(seed+i,SiteArt.BOOKS.size())])
				book.rotation.y=i*0.24
		"complex_temple","living_museum","mausoleum","silent_tower":
			var shaft := MiniatureFactory.cylinder(root,p,0.14,0.17,width*0.84,STONE.lightened(0.10))
			shaft.rotation.z=PI*0.5
			for side: float in [-1.0,1.0]:
				var ring := MiniatureFactory.cylinder(root,p+Vector3(side*width*0.38,0,0),0.19,0.19,0.08,STONE.darkened(0.18))
				ring.rotation.z=PI*0.5
		"sunken_streets","haunted_houses","the_keep":
			for i in 3:
				var beam := MiniatureFactory.box(root,at+Vector3(0,0.08+i*0.07,0),Vector3(width*0.85,0.10,0.19),WOOD.lightened(i*0.06))
				beam.rotation.y=i*0.85
		_:
			for i in 2:
				var block := MiniatureFactory.box(root,at+Vector3((i-0.5)*width*0.35,0.12+i*0.065,0),Vector3(width*0.47,0.22,width*0.55),STONE)
				block.rotation.y=seed*0.37+i*0.32


static func crate(root: Node3D,at: Vector3,s: float) -> void:
	MiniatureFactory.box(root,at+Vector3.UP*s*0.5,Vector3.ONE*s,WOOD)
	for side: float in [-1.0,1.0]:
		for z: float in [-1.0,1.0]:
			MiniatureFactory.box(root,at+Vector3(side*s*0.42,s*0.5,z*s*0.5),Vector3(s*0.12,s*0.98,s*0.06),WOOD.darkened(0.28))
		MiniatureFactory.box(root,at+Vector3(0,s*0.87,side*s*0.51),Vector3(s,0.13*s,0.07*s),IRON)
		var brace := MiniatureFactory.box(root,at+Vector3(0,s*0.50,side*s*0.51),Vector3(s*1.04,s*0.13,s*0.06),WOOD.lightened(0.18))
		brace.rotation.z=side*0.72
	MiniatureFactory.box(root,at+Vector3.UP*s*1.02,Vector3(s*0.86,0.045*s,s*0.90),SNOW)


static func barrel(root: Node3D,at: Vector3,s: float) -> void:
	MiniatureFactory.cylinder(root,at+Vector3.UP*s*0.5,s*0.36,s*0.36,s,WOOD)
	MiniatureFactory.cylinder(root,at+Vector3.UP*s*0.50,s*0.43,s*0.43,s*0.64,WOOD.lightened(0.10))
	for y: float in [0.19,0.78]:
		MiniatureFactory.cylinder(root,at+Vector3.UP*s*y,s*0.42,s*0.42,s*0.08,IRON)
	MiniatureFactory.cylinder(root,at+Vector3.UP*s*1.012,s*0.31,s*0.31,s*0.04,SNOW)


static func landmark(root: Node3D,at: Vector3,scenario: String,seed: int) -> void:
	match scenario:
		"mausoleum":
			for i in 3:
				var p := at+Vector3((i-1)*0.67,0,0)
				MiniatureFactory.box(root,p+Vector3.UP*0.12,Vector3(0.56,0.24,0.45),STONE.darkened(0.15))
				MiniatureFactory.box(root,p+Vector3.UP*0.58,Vector3(0.43,0.80,0.22),STONE)
				MiniatureFactory.sphere(root,p+Vector3.UP*1.0,Vector3(0.43,0.32,0.22),STONE)
				MiniatureFactory.box(root,p+Vector3(0,0.67,-0.12),Vector3(0.26,0.055,0.03),STONE.darkened(0.36))
		"complex_temple","dreams_well","silent_tower","living_museum":
			MiniatureFactory.cylinder(root,at+Vector3.UP*0.22,0.42,0.52,0.44,STONE)
			MiniatureFactory.cylinder(root,at+Vector3.UP*0.78,0.18,0.26,0.70,BRASS)
			MiniatureFactory.cylinder(root,at+Vector3.UP*1.17,0.52,0.30,0.32,IRON)
			for i in 4:
				var a := TAU*i/4.0
				CreatureSculpt.limb(root,at+Vector3(cos(a)*0.2,1.25,sin(a)*0.2),at+Vector3(cos(a)*0.07,1.67,sin(a)*0.07),0.14,Color("cf9250"),0.02)
		"sunken_streets","haunted_houses":
			crate(root,at,0.83)
			barrel(root,at+Vector3(0.92,0,0.22),0.74)
			for side: float in [-1.0,1.0]:
				CreatureSculpt.limb(root,at+Vector3(side*0.43,0.04,-0.85),at+Vector3(side*0.43,0.76,0.20),0.075,WOOD,1.0)
		_:
			crate(root,at,0.82)
			barrel(root,at+Vector3(0.89,0,0.18),0.80)
			if seed%2==0:
				crate(root,at+Vector3(0.02,0.82,0.04),0.62)
