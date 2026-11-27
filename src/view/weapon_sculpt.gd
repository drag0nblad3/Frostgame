class_name WeaponSculpt
extends RefCounted
## Bevelled blades, reinforced shields and carved staff crowns.

const STEEL := Color(0.67, 0.73, 0.77)
const BRASS := Color(0.76, 0.57, 0.26)
const WOOD := Color(0.28, 0.19, 0.12)


static func metal(node: MeshInstance3D) -> void:
	var mat: StandardMaterial3D = node.material_override
	mat.metallic = 0.55
	mat.roughness = 0.38


static func sword(root: Node3D, length: float, broad: bool) -> void:
	var width := 0.13 if broad else 0.095
	var x := 0.37
	var bottom := 0.83
	var blade := CylinderMesh.new()
	blade.top_radius = width * 0.46
	blade.bottom_radius = width * 0.65
	blade.height = length * 0.85
	blade.radial_segments = 4
	var m := MiniatureFactory.mesh(root, blade, Vector3(x, bottom + length * 0.425, -0.08), STEEL)
	m.scale.z = 0.40
	metal(m)
	var tip := CylinderMesh.new()
	tip.top_radius = 0.0
	tip.bottom_radius = blade.top_radius
	tip.height = length * 0.15
	tip.radial_segments = 4
	var end := MiniatureFactory.mesh(root, tip, Vector3(x, bottom + length * 0.925, -0.08), STEEL.lightened(0.12))
	end.scale.z = 0.40
	metal(end)
	metal(MiniatureFactory.box(root, Vector3(x, 0.80, -0.08), Vector3(width * 2.8, 0.055, 0.075), BRASS))
	MiniatureFactory.cylinder(root, Vector3(x, 0.68, -0.08), 0.037, 0.037, 0.20, WOOD)
	metal(MiniatureFactory.sphere(root, Vector3(x, 0.57, -0.08), Vector3.ONE * 0.105, BRASS))
	# Broad central fuller and a stepped crossguard read even at battle zoom.
	metal(MiniatureFactory.box(root,Vector3(x,bottom+length*0.40,-0.104),Vector3(width*0.20,length*0.67,0.009),STEEL.darkened(0.32)))
	for side: float in [-1.0,1.0]:
		metal(MiniatureFactory.sphere(root,Vector3(x+side*width*1.32,0.80,-0.08),Vector3(0.055,0.07,0.07),BRASS.lightened(0.15)))
	for i in 3:
		MiniatureFactory.cylinder(root,Vector3(x,0.63+i*0.045,-0.08),0.043,0.043,0.016,WOOD.lightened(0.22))


static func shield(root: Node3D, knight: bool) -> void:
	var center := Vector3(-0.33, 0.84, -0.24)
	if knight:
		ArmourShapes.heater_shield(root,center)
		return
	var shield_color := Color(0.32, 0.42, 0.53)
	var r := 0.27 if knight else 0.23
	var rim := MiniatureFactory.cylinder(root, center, r, r, 0.075, BRASS)
	rim.rotation.x = PI * 0.5
	metal(rim)
	var face := MiniatureFactory.cylinder(root, center + Vector3(0, 0, -0.05), r * 0.83, r * 0.83, 0.055, shield_color)
	face.rotation.x = PI * 0.5
	metal(MiniatureFactory.sphere(root, center + Vector3(0, 0, -0.10), Vector3.ONE * 0.15, STEEL))
	for i in 3:
		var dx := (i-1)*r*0.46
		var span := 2.0*sqrt(maxf(0.0,pow(r*0.76,2)-dx*dx))
		MiniatureFactory.box(root,center+Vector3(dx,0,-0.081),Vector3(0.017,span,0.015),shield_color.darkened(0.28))
	if knight:
		for side: float in [-1.0,1.0]:
			metal(MiniatureFactory.box(root,center+Vector3(side*r*0.38,0,-0.09),Vector3(0.055,r*0.92,0.018),BRASS))
	for i in 8:
		var angle := TAU * i / 8.0
		metal(MiniatureFactory.sphere(root, center + Vector3(cos(angle) * r * 0.9, sin(angle) * r * 0.9, -0.047), Vector3.ONE * 0.037, STEEL))


static func staff(root: Node3D) -> void:
	MiniatureFactory.cylinder(root, Vector3(0.39, 0.92, -0.06), 0.041, 0.054, 1.68, WOOD.lightened(0.16))
	for y: float in [0.35, 0.79, 1.55]:
		metal(MiniatureFactory.cylinder(root, Vector3(0.39, y, -0.06), 0.059, 0.059, 0.075, BRASS))
	for i in 3:
		var angle := TAU * i / 3.0
		var at := Vector3(0.39 + cos(angle) * 0.10, 1.79, -0.06 + sin(angle) * 0.10)
		CreatureSculpt.limb(root, Vector3(0.39, 1.64, -0.06), at, 0.035, BRASS)
	var crystal := CylinderMesh.new()
	crystal.top_radius = 0.0
	crystal.bottom_radius = 0.12
	crystal.height = 0.23
	crystal.radial_segments = 5
	var gem := MiniatureFactory.mesh(root, crystal, Vector3(0.39, 1.82, -0.06), Color(0.35, 0.78, 0.88))
	var mat: StandardMaterial3D = gem.material_override
	mat.emission_enabled = true
	mat.emission = Color(0.14, 0.35, 0.42)
