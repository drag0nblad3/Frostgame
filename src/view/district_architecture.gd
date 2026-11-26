class_name DistrictArchitecture
extends RefCounted
## Distinct roofs and facade relief. Gameplay geometry is never changed.
const TIMBER := Color("6c5241")
const BRASS := Color("a38b5d")


static func finish(root: Node3D,at: Vector2,ground: float,h: float,w: float,d: float,tint: Color,seed: int) -> void:
	var c := Vector3(at.x,ground+h*0.5,at.y)
	var stone := tint.darkened(0.12)
	var pale := tint.lightened(0.22)
	var roof := tint.darkened(0.20)
	# Street-level door relief and contrasting lintels on distant buildings.
	for side: float in [-1.0,1.0]:
		var z := at.y+side*(d*0.5+0.025)
		MiniatureFactory.box(root,Vector3(at.x,ground+0.61,z),Vector3(w*0.22,1.20,0.055),TIMBER.lerp(stone,0.58))
		MiniatureFactory.box(root,Vector3(at.x,ground+1.25,z),Vector3(w*0.31,0.16,0.13),pale)
		for x: float in [-1.0,1.0]:
			MiniatureFactory.box(root,Vector3(at.x+x*w*0.46,ground+h*0.5,z),Vector3(0.13,h*0.96,0.11),pale.darkened(0.12))
		MiniatureFactory.box(root,Vector3(at.x,ground+h*0.64,z),Vector3(w,0.14,0.10),pale)
		if seed%3==0:
			for x: float in [-1.0,1.0]:
				var brace := MiniatureFactory.box(root,Vector3(at.x+x*w*0.27,ground+h*0.78,z),Vector3(w*0.40,0.14,0.09),TIMBER.lerp(stone,0.4))
				brace.rotation.z=x*0.66
	# Chimneys or bell-caps vary the roofs; no taller than the distant skyline.
	if seed%3==0:
		var y := ground+h+0.56
		MiniatureFactory.box(root,Vector3(at.x+w*0.28,y,at.y+d*0.17),Vector3(0.44,0.94,0.45),roof)
		MiniatureFactory.box(root,Vector3(at.x+w*0.28,y+0.46,at.y+d*0.17),Vector3(0.57,0.15,0.56),pale)
	elif seed%3==1:
		for side: float in [-1.0,1.0]:
			MiniatureFactory.box(root,c+Vector3(side*w*0.47,h*0.5+0.13,0),Vector3(0.15,0.23,d),pale)
	else:
		var cap := PrismMesh.new()
		cap.size=Vector3(w*0.44,0.48,d*0.42)
		MiniatureFactory.mesh(root,cap,c+Vector3(w*0.25,h*0.5+0.92,d*0.20),pale)


static func relief(root: Node3D,p: TerrainPiece,seed: int,scenario: String) -> void:
	var r := p.rect
	var h := p.kind.height
	if h<1.8:
		return
	var trim := Color("8f9b9f")
	var wood := TIMBER if p.kind.id=="hut_wall" else Color("566167")
	# Shallow decorative timber braces or masonry quoins on existing faces.
	# Relief never creates a doorway or exceeds the original terrain height.
	for swapped in [false,true]:
		var span := r.size.y if swapped else r.size.x
		if span<1.6:
			continue
		for side: float in [-1.0,1.0]:
			var count := clampi(floori(span/1.65),1,4)
			for i in count:
				var u := (i+0.5)*span/count
				var x := r.get_center().x+side*(r.size.x*0.5+0.008) if swapped else r.position.x+u
				var z := r.position.y+u if swapped else r.get_center().y+side*(r.size.y*0.5+0.008)
				if p.kind.id=="hut_wall":
					var brace := MiniatureFactory.box(root,Vector3(x,h*0.48,z),Vector3(0.045,0.13,0.78) if swapped else Vector3(0.78,0.13,0.045),wood)
					if swapped:
						brace.rotation.x=0.50
					else:
						brace.rotation.z=0.50
				else:
					for j in 3:
						var y := 0.32+j*0.24
						MiniatureFactory.box(root,Vector3(x,y,z),Vector3(0.055,0.13,0.30) if swapped else Vector3(0.30,0.13,0.055),trim.darkened(j*0.07))
					if scenario in ["silent_tower","complex_temple","mausoleum"] and (seed+i)%3==0 and h>2.6:
						MiniatureFactory.box(root,Vector3(x,h*0.59,z),Vector3(0.06,0.60,0.38) if swapped else Vector3(0.38,0.60,0.06),wood)
						MiniatureFactory.box(root,Vector3(x,h*0.59,z),Vector3(0.075,0.06,0.39) if swapped else Vector3(0.39,0.06,0.075),BRASS)
