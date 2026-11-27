class_name SkylineLandmarks
extends RefCounted
## Distinct non-playable architecture beyond the board. Baked into the district.


static func build(root: Node3D,at: Vector2,ground: float,tone: Color,scenario: String,side: int,seed: int) -> void:
	var site := Node3D.new()
	root.add_child(site)
	site.position=Vector3(at.x,ground,at.y)
	site.rotation.y=side*PI*0.5
	var stone := tone.darkened(0.18)
	var trim := tone.lightened(0.20)
	if scenario in ["mausoleum","complex_temple","living_museum","silent_tower"] or seed%3==0:
		_gate(site,stone,trim)
	elif seed%3==1:
		_turret(site,stone,trim)
	else:
		_hall(site,stone,trim)
	MiniatureBatch.bake(site)
	for child in site.get_children():
		if child is MeshInstance3D:
			child.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _gate(root: Node3D,stone: Color,trim: Color) -> void:
	# Open archway is entirely outside the tactical surface.
	for x: float in [-1.70,1.70]:
		MiniatureFactory.box(root,Vector3(x,1.75,0),Vector3(1.15,3.5,1.8),stone)
		MiniatureFactory.box(root,Vector3(x,0.22,0),Vector3(1.42,0.44,2.0),trim)
		MiniatureFactory.box(root,Vector3(x,3.40,0),Vector3(1.36,0.26,2.0),trim)
		for z: float in [-0.92,0.92]:
			MiniatureFactory.box(root,Vector3(x,2.1,z),Vector3(0.16,1.7,0.07),trim.darkened(0.25))
	for i in 9:
		var angle := PI*float(i)/8.0
		var node := MiniatureFactory.box(root,Vector3(cos(angle)*1.70,3.25+sin(angle)*1.55,0),Vector3(0.60,0.53,1.62),stone.lightened((i%3)*0.06))
		node.rotation.z=angle-PI*0.5
	MiniatureFactory.box(root,Vector3(0,5.02,0),Vector3(1.08,0.25,1.86),trim)


static func _turret(root: Node3D,stone: Color,trim: Color) -> void:
	MiniatureFactory.cylinder(root,Vector3(0,2.7,0),1.42,1.67,5.4,stone)
	for y: float in [0.28,2.15,4.85]:
		MiniatureFactory.cylinder(root,Vector3(0,y,0),1.72,1.72,0.20,trim)
	var roof := MiniatureFactory.cylinder(root,Vector3(0,6.30,0),0.08,1.72,1.8,trim.darkened(0.18))
	for i in 4:
		var a := TAU*i/4.0
		var window := MiniatureFactory.box(root,Vector3(cos(a)*1.44,3.3,sin(a)*1.44),Vector3(0.36,1.08,0.06),stone.darkened(0.45))
		window.rotation.y=PI*0.5-a
	MiniatureFactory.sphere(root,Vector3(0,7.28,0),Vector3.ONE*0.24,Color("b3a378"))


static func _hall(root: Node3D,stone: Color,trim: Color) -> void:
	MiniatureFactory.box(root,Vector3(0,1.75,0),Vector3(4.4,3.5,2.9),stone)
	var shape := PrismMesh.new()
	shape.size=Vector3(4.55,1.55,3.05)
	MiniatureFactory.mesh(root,shape,Vector3(0,4.20,0),trim)
	for x: float in [-1.65,0.0,1.65]:
		MiniatureFactory.box(root,Vector3(x,1.72,-1.48),Vector3(0.20,3.4,0.20),trim.darkened(0.2))
		MiniatureFactory.box(root,Vector3(x+0.45,2.15,-1.49),Vector3(0.44,0.90,0.065),stone.darkened(0.43))
	for x: float in [-1.6,1.6]:
		MiniatureFactory.box(root,Vector3(x,4.65,0.60),Vector3(0.53,1.32,0.56),stone.darkened(0.16))
		MiniatureFactory.box(root,Vector3(x,5.34,0.60),Vector3(0.68,0.16,0.70),trim)
