class_name ExteriorLandforms
extends RefCounted
## Ice, canal and planar silhouettes: scenic only, never tactical surfaces.

static func quay(root: Node3D,kind: String,at: Vector3,stone: Color,trim: Color,side: int) -> void:
	var axis:=ExteriorStructures.oriented(Vector3(1,0,0),side)
	var across:=ExteriorStructures.oriented(Vector3(0,0,1),side)
	if kind=="bridge":
		# Flat distant bridge span with low parapets.
		MiniatureFactory.box(root,at+Vector3.UP*0.48,ExteriorStructures.oriented(Vector3(2.2,0.45,5.3),side),stone)
		for sign_value: float in [-1.0,1.0]:
			MiniatureFactory.box(root,at+axis*sign_value*1.08+Vector3.UP*0.90,ExteriorStructures.oriented(Vector3(0.18,0.40,5.3),side),trim)
			MiniatureFactory.box(root,at+across*sign_value*2.4+Vector3.UP*0.22,ExteriorStructures.oriented(Vector3(2.45,0.44,0.60),side),stone)
	else:
		MiniatureFactory.box(root,at+Vector3.UP*0.31,ExteriorStructures.oriented(Vector3(4.5,0.62,0.95),side),stone)
		for i in 3:
			MiniatureFactory.cylinder(root,at+axis*(i-1)*1.7+Vector3.UP*0.8,0.14,0.24,0.40,trim)


static func ice(root: Node3D,kind: String,at: Vector3,seed: int) -> void:
	var tint:=Color("8aa9b9")
	if kind=="drift":
		for i in 3:
			MiniatureFactory.sphere(root,at+Vector3((i-1)*1.0,0.18,0.25*sin(i)),Vector3(2.15,0.58,1.8),Color("d0dce0"))
		return
	var count:=5 if kind=="ice_ridge" else 3
	for i in count:
		var h:=(2.6 if kind=="ice_ridge" else 0.9)+float(posmod(seed+i*5,8))*0.22
		var p:=at+Vector3((i-(count-1)*0.5)*0.95,0,sin(seed+i)*0.65)
		var spike:=MiniatureFactory.cylinder(root,p+Vector3.UP*h*0.5,0.05,0.65,h,tint.lightened((i%3)*0.10))
		spike.rotation.z=0.15*sin(i+seed)
		MiniatureFactory.sphere(root,p+Vector3.UP*0.13,Vector3(1.8,0.37,1.45),Color("c4d4dc"))


static func realm(root: Node3D,kind: String,at: Vector3,base: Color,edge: Color,seed: int,side: int) -> void:
	var accent:=edge.lerp(Color("9e8bca"),0.48)
	match kind:
		"memory":
			RealmScenery._memory(root,at+Vector3.UP*0.45,base,accent,seed)
			var echo:=MiniatureFactory.box(root,at+Vector3(0,2.6,0.85),Vector3(0.42,1.65,0.18),accent.darkened(0.25))
			echo.rotation.z=-0.48
		"shard":
			RealmScenery._shard(root,at,base,accent,seed)
		"floating","broken_bridge":
			var h:=1.6+float(posmod(seed,5))*0.35
			var slab:=MiniatureFactory.box(root,at+Vector3.UP*h,Vector3(3.3,0.55,2.9),base)
			slab.rotation.y=seed*0.11
			var underside:=MiniatureFactory.cylinder(root,at+Vector3.UP*(h-0.64),1.38,0.14,1.0,base.darkened(0.30))
			underside.rotation.y=seed*0.11
			if kind=="broken_bridge":
				for i in 2:
					var step:=MiniatureFactory.box(root,at+Vector3(0,h+0.15+i*0.42,(i+1)*1.2),Vector3(2.0,0.28,1.1),accent.darkened(0.28))
					step.rotation.x=(i+1)*0.19
			else:
				RealmScenery._shard(root,at+Vector3.UP*(h+0.28),base,accent,seed)
		"pyramid":
			for i in 4:
				var width:=4.6-i*1.0
				MiniatureFactory.box(root,at+Vector3.UP*(i*0.72+0.36),Vector3(width,0.72,width),base.lightened(i*0.08))
			MiniatureFactory.cylinder(root,at+Vector3.UP*3.16,0.0,0.34,0.56,accent)
		"tether":
			RealmScenery._pillar(root,at,base,accent,seed)
			for i in 3:
				var shard:=MiniatureFactory.box(root,at+Vector3(cos(i*TAU/3.0)*1.35,3.7+0.12*i,sin(i*TAU/3.0)*1.35),Vector3(0.24,0.95,0.24),accent)
				shard.rotation=Vector3(0.3,seed*0.1,0.5)
		"ring":
			# Segmented, jagged arc rather than ordinary rectangular buildings.
			for i in 11:
				var a:=PI*float(i)/10.0
				var local:=Vector3(cos(a)*2.55,0.7+sin(a)*2.55,0)
				var block:=MiniatureFactory.box(root,at+ExteriorStructures.oriented(local,side),ExteriorStructures.oriented(Vector3(0.75,0.48,0.62),side),base.lightened(0.10*(i%3)))
				if side%2==0:
					block.rotation.z=a-PI*0.5
				else:
					block.rotation.x=PI*0.5-a
			MiniatureFactory.sphere(root,at+Vector3.UP*1.3,Vector3.ONE*0.65,accent)
