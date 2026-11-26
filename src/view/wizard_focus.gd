class_name WizardFocus
extends RefCounted
## Different staff crowns, with small school-colored magical foci. All geometry
## stays attached to the existing animated hand pivot.
const WOOD := Color("594534")
const BONE := Color("c9bda5")


static func staff(root: Node3D,school: String) -> void:
	var trim := SchoolArt.accent(school)
	var gem := SchoolArt.glow(school)
	var p := Vector3(0.39,1.74,-0.06)
	MiniatureFactory.cylinder(root,Vector3(p.x,0.90,p.z),0.043,0.052,1.68,WOOD)
	for y: float in [0.22,0.79,1.55]:
		WeaponSculpt.metal(MiniatureFactory.cylinder(root,Vector3(p.x,y,p.z),0.057,0.057,0.075,trim))
	match school:
		"chronomancer":
			_ring(root,p,0.14,trim)
			for side: float in [-1.0,1.0]:
				CreatureSculpt.limb(root,p+Vector3(-0.08,side*0.09,-0.015),p+Vector3(0.08,-side*0.09,-0.015),0.018,trim,1.0)
			_gem(root,p,gem,0.065)
		"elementalist":
			for side: float in [-1.0,1.0]:
				CreatureSculpt.limb(root,p-Vector3.UP*0.09,p+Vector3(side*0.12,0.14,0),0.045,trim,0.1)
			_gem(root,p+Vector3.UP*0.10,gem,0.14)
		"enchanter":
			WeaponSculpt.metal(MiniatureFactory.box(root,p,Vector3(0.30,0.17,0.16),trim))
			_gem(root,p-Vector3.FORWARD*0.09,gem,0.08)
		"illusionist":
			_ring(root,p,0.15,trim)
			_ring(root,p+Vector3(0.07,0.045,0),0.11,trim)
			_gem(root,p,gem,0.09)
		"necromancer":
			MiniatureFactory.sphere(root,p,Vector3(0.22,0.24,0.19),BONE)
			MiniatureFactory.box(root,p+Vector3(0,-0.09,-0.025),Vector3(0.13,0.09,0.12),BONE)
			for side: float in [-1.0,1.0]:
				_gem(root,p+Vector3(side*0.055,0.02,-0.09),gem,0.047)
		"sigilist":
			WeaponSculpt.metal(MiniatureFactory.box(root,p,Vector3(0.22,0.28,0.07),trim))
			MiniatureFactory.box(root,p+Vector3(0,0,-0.045),Vector3(0.17,0.23,0.035),BONE)
			for y: float in [-0.06,0.0,0.06]:
				MiniatureFactory.box(root,p+Vector3(0,y,-0.07),Vector3(0.11,0.017,0.014),gem.darkened(0.2))
		"soothsayer":
			_ring(root,p,0.15,trim)
			_gem(root,p,gem,0.19)
		"summoner":
			for side: float in [-1.0,1.0]:
				var a := p+Vector3(side*0.06,-0.09,0)
				var b := p+Vector3(side*0.14,0.08,0)
				CreatureSculpt.limb(root,a,b,0.045,BONE,0.65)
				CreatureSculpt.limb(root,b,p+Vector3(side*0.07,0.17,0),0.027,BONE,0.02)
			_gem(root,p,gem,0.12)
		"thaumaturge":
			_ring(root,p,0.14,trim)
			for i in 8:
				var angle := TAU*i/8.0
				var dir := Vector3(cos(angle),sin(angle),0)
				CreatureSculpt.limb(root,p+dir*0.13,p+dir*0.23,0.025,trim,0.02)
			_gem(root,p,gem,0.11)
		"witch":
			for side: float in [-1.0,1.0]:
				var a := p+Vector3(0,-0.10,0)
				var b := p+Vector3(side*0.14,0.08,0)
				CreatureSculpt.limb(root,a,b,0.045,WOOD,0.60)
				CreatureSculpt.limb(root,b,p+Vector3(side*0.07,0.19,0),0.028,WOOD,0.05)
			_gem(root,p+Vector3.UP*0.07,gem,0.11)
		_:
			_gem(root,p,gem,0.14)


static func _ring(root: Node3D,at: Vector3,r: float,color: Color) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius=r*0.78
	torus.outer_radius=r
	torus.rings=12
	torus.ring_segments=6
	var node := MiniatureFactory.mesh(root,torus,at,color)
	node.rotation.x=PI*0.5
	WeaponSculpt.metal(node)


static func _gem(root: Node3D,at: Vector3,color: Color,size: float) -> void:
	var node := MiniatureFactory.sphere(root,at,Vector3.ONE*size,color)
	var mat := node.material_override as StandardMaterial3D
	mat.emission_enabled=true
	mat.emission=color*0.24
