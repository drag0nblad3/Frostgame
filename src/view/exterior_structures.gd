class_name ExteriorStructures
extends RefCounted
## Compact architectural silhouettes for non-playable districts.

static func oriented(v: Vector3,side: int) -> Vector3:
	return Vector3(v.z,v.y,v.x) if side%2==1 else v


static func ruin(root: Node3D,at: Vector3,stone: Color,trim: Color,tall: bool,seed: int) -> void:
	for i in 5:
		var h:=(1.5+float(posmod(seed+i*3,7))*0.42) if tall else (0.25+float(i%3)*0.18)
		var p:=at+Vector3((i-2)*0.66,h*0.5,sin(i*2.1)*0.35)
		MiniatureFactory.box(root,p,Vector3(0.72,h,0.62),stone.lightened(i*0.03))
		if tall:
			MiniatureFactory.box(root,p+Vector3.UP*(h*0.5),Vector3(0.79,0.14,0.7),trim)
	for i in 3:
		var b:=MiniatureFactory.box(root,at+Vector3((i-1)*0.80,0.24,1.1),Vector3(0.75,0.48,0.65),stone)
		b.rotation.y=seed+i*0.9


static func defence(root: Node3D,kind: String,at: Vector3,stone: Color,wood: Color,side: int) -> void:
	var timber:=kind in ["palisade","fence","watchtower"]
	if kind=="watchtower":
		for x in [-1.0,1.0]:
			for z in [-1.0,1.0]:
				MiniatureFactory.box(root,at+Vector3(x,2.25,z),Vector3(0.22,4.5,0.22),wood)
		MiniatureFactory.box(root,at+Vector3.UP*3.5,Vector3(2.6,0.25,2.6),wood)
		MiniatureFactory.box(root,at+Vector3.UP*4.65,Vector3(2.7,0.30,2.7),wood.darkened(0.18))
		for x in [-1.0,1.0]:
			MiniatureFactory.box(root,at+Vector3(x*1.2,4.0,0),Vector3(0.15,0.78,2.6),wood)
		return
	var h:=1.1 if kind=="fence" else (2.7 if kind=="palisade" else 3.2)
	if timber:
		for i in 7:
			var p:=at+oriented(Vector3((i-3)*0.48,0,0),side)
			MiniatureFactory.cylinder(root,p+Vector3.UP*h*0.5,0.18,0.20,h,wood.lightened((i%3)*0.08))
			if kind=="palisade":
				MiniatureFactory.cylinder(root,p+Vector3.UP*(h+0.18),0.0,0.18,0.36,wood)
		for y in [0.4,h*0.68]:
			MiniatureFactory.box(root,at+Vector3.UP*y,oriented(Vector3(3.6,0.17,0.46),side),wood.darkened(0.22))
	else:
		MiniatureFactory.box(root,at+Vector3.UP*h*0.5,oriented(Vector3(5.0,h,0.85),side),stone)
		for i in 5:
			MiniatureFactory.box(root,at+oriented(Vector3((i-2)*1.0,h+0.32,0),side),oriented(Vector3(0.63,0.64,0.92),side),stone.lightened(0.15))
		if kind=="fortress":
			for x in [-2.15,2.15]:
				MiniatureFactory.cylinder(root,at+oriented(Vector3(x,2.6,0),side),0.82,0.98,5.2,stone)
				MiniatureFactory.cylinder(root,at+oriented(Vector3(x,5.2,0),side),1.02,1.02,0.28,stone.lightened(0.20))


static func dwelling(root: Node3D,kind: String,at: Vector3,stone: Color,wood: Color,trim: Color,side: int,seed: int) -> void:
	var w:=4.2 if kind in ["warehouse","market"] else 2.8
	var d:=2.6
	var h:=2.4 if kind=="warehouse" else 1.8
	if kind in ["tent","stall","market"]:
		var cloth:=Color("a17759").lerp(trim,0.36) if kind=="tent" else Color("a59b78").lerp(trim,0.40)
		for x in [-1.0,1.0]:
			for z in [-1.0,1.0]:
				MiniatureFactory.box(root,at+Vector3(x*w*0.44,h*0.50,z*d*0.44),Vector3(0.12,h,0.12),wood)
		if kind=="tent":
			var tent:=PrismMesh.new()
			tent.size=Vector3(w,2.25,d)
			MiniatureFactory.mesh(root,tent,at+Vector3.UP*1.16,cloth)
		else:
			var canopy:=PrismMesh.new()
			canopy.size=Vector3(w+0.28,0.70,d+0.26)
			MiniatureFactory.mesh(root,canopy,at+Vector3.UP*(h+0.28),cloth)
			MiniatureFactory.box(root,at+Vector3.UP*0.85,Vector3(w*0.86,0.20,d*0.58),wood)
		return
	MiniatureFactory.box(root,at+Vector3.UP*h*0.50,Vector3(w,h,d),stone if kind=="warehouse" else wood)
	var roof:=PrismMesh.new()
	roof.size=Vector3(w+0.28,1.05,d+0.25)
	MiniatureFactory.mesh(root,roof,at+Vector3.UP*(h+0.47),trim)
	for x in [-1.0,1.0]:
		MiniatureFactory.box(root,at+Vector3(x*w*0.44,h*0.5,-d*0.51),Vector3(0.16,h,0.1),wood.darkened(0.25))
		MiniatureFactory.box(root,at+Vector3(x*w*0.24,h*0.64,-d*0.52),Vector3(0.43,0.59,0.08),stone.darkened(0.45))
	MiniatureFactory.box(root,at+Vector3(0,0.58,-d*0.52),Vector3(0.65,1.16,0.1),wood.darkened(0.35))
	if kind=="windmill":
		MiniatureFactory.cylinder(root,at+Vector3.UP*2.5,0.86,1.1,5.0,stone)
		for i in 4:
			var blade:=MiniatureFactory.box(root,at+Vector3(cos(i*PI*0.5+0.42)*1.28,4.1+sin(i*PI*0.5+0.42)*1.28,-1.2),Vector3(2.0,0.32,0.13),wood)
			blade.rotation.z=i*PI*0.5+0.42


static func monument(root: Node3D,kind: String,at: Vector3,stone: Color,trim: Color,side: int) -> void:
	var w:=4.8 if kind in ["gallery","archive","shrine","burned_shrine","mausoleum"] else 3.6
	var h:=2.6 if kind=="crypt" else 3.7
	var depth:=2.8
	MiniatureFactory.box(root,at+Vector3.UP*0.17,oriented(Vector3(w+0.25,0.34,depth+0.25),side),stone)
	if kind in ["crypt","mausoleum"]:
		MiniatureFactory.box(root,at+Vector3.UP*(h*0.5+0.34),oriented(Vector3(w*0.78,h,depth*0.86),side),stone)
	for i in 4:
		var x:=(i-1.5)*w*0.25
		var height:=h*(0.55 if kind=="burned_shrine" and i%2==0 else 1.0)
		var p:=at+oriented(Vector3(x,0,-depth*0.38),side)
		MiniatureFactory.cylinder(root,p+Vector3.UP*(height*0.5+0.34),0.19,0.24,height,trim)
		MiniatureFactory.box(root,p+Vector3.UP*(height+0.32),Vector3(0.52,0.22,0.52),stone.lightened(0.18))
	if kind!="burned_shrine":
		MiniatureFactory.box(root,at+Vector3.UP*(h+0.48),oriented(Vector3(w,0.32,depth),side),trim)
		var roof:=PrismMesh.new()
		roof.size=oriented(Vector3(w+0.1,0.92,depth+0.1),side)
		MiniatureFactory.mesh(root,roof,at+Vector3.UP*(h+1.0),stone.lightened(0.15))
	if kind=="archive":
		shelves(root,at+Vector3(0,0.34,0.45),stone,side,3)


static func ornament(root: Node3D,kind: String,at: Vector3,stone: Color,trim: Color) -> void:
	if kind=="basin":
		MiniatureFactory.cylinder(root,at+Vector3.UP*0.27,1.15,1.28,0.54,stone)
		MiniatureFactory.cylinder(root,at+Vector3.UP*0.56,1.0,1.0,0.05,Color("568caa"))
		MiniatureFactory.cylinder(root,at+Vector3.UP*0.85,0.17,0.25,1.1,trim)
		return
	MiniatureFactory.box(root,at+Vector3.UP*0.25,Vector3(1.3,0.50,1.3),stone)
	match kind:
		"statue":
			MiniatureFactory.cylinder(root,at+Vector3.UP*1.24,0.29,0.46,1.48,trim)
			MiniatureFactory.sphere(root,at+Vector3.UP*2.18,Vector3(0.51,0.62,0.51),trim)
			MiniatureFactory.box(root,at+Vector3(-0.42,1.65,0),Vector3(0.18,0.72,0.22),trim)
		"obelisk":
			MiniatureFactory.cylinder(root,at+Vector3.UP*2.00,0.30,0.43,3.0,stone)
			MiniatureFactory.cylinder(root,at+Vector3.UP*3.78,0.0,0.31,0.56,trim)
		"pillar":
			MiniatureFactory.cylinder(root,at+Vector3.UP*2.3,0.35,0.42,3.6,trim)
		"brazier":
			MiniatureFactory.cylinder(root,at+Vector3.UP*0.86,0.18,0.32,0.78,stone)
			MiniatureFactory.cylinder(root,at+Vector3.UP*1.29,0.58,0.28,0.30,stone.darkened(0.35))
			for i in 3:
				MiniatureFactory.cylinder(root,at+Vector3((i-1)*0.20,1.62,0),0.0,0.18,0.68,Color("e59448").lightened(i*0.13))


static func shelves(root: Node3D,at: Vector3,wood: Color,side: int,seed: int) -> void:
	for x in [-1.45,1.45]:
		MiniatureFactory.box(root,at+oriented(Vector3(x,1.55,0),side),oriented(Vector3(0.16,3.1,0.95),side),wood)
	for i in 4:
		var y:=0.22+i*0.82
		MiniatureFactory.box(root,at+Vector3.UP*y,oriented(Vector3(3.1,0.16,0.95),side),wood.darkened(0.16))
		for j in 7:
			var h:=0.40+float(posmod(seed+i*7+j*3,4))*0.07
			MiniatureFactory.box(root,at+oriented(Vector3((j-3)*0.37,y+0.08+h*0.5,0),side),oriented(Vector3(0.27,h,0.60),side),SiteArt.BOOKS[posmod(seed+i+j,SiteArt.BOOKS.size())])
