class_name GolemSculpt
extends RefCounted
## Three tiers of enchanted stone and bronze, with carved cores and heavy limbs.


static func create(root: Node3D, id: String, faction: Color) -> void:
	var small := id == "small_construct"
	var large := id == "large_construct"
	var stone := Color(0.44, 0.49, 0.51) if not small else Color(0.58, 0.47, 0.31)
	var trim := Color(0.31, 0.38, 0.41) if large else Color(0.63, 0.49, 0.28)
	var light := Color(0.43, 0.83, 0.92) if large else Color(0.75, 0.88, 0.54)
	for side: float in [-1.0, 1.0]:
		var shin := Vector3(side * 0.18, 0.29, 0)
		MiniatureFactory.cylinder(root, shin, 0.15, 0.17, 0.40, stone).rotation.z = side * 0.10
		MiniatureFactory.box(root, shin + Vector3(0, -0.20, -0.06), Vector3(0.29, 0.17, 0.36), trim)
		MiniatureFactory.sphere(root, shin + Vector3(0, 0.22, 0), Vector3.ONE * 0.26, trim)
		var pivot := MiniaturePose.arm(root, side > 0)
		var first := root.get_child_count()
		var shoulder := Vector3(side * 0.31, 1.10, 0)
		var elbow := Vector3(side * 0.43, 0.83, -0.05)
		MiniatureFactory.sphere(root, shoulder, Vector3(0.38, 0.33, 0.39), stone.lightened(0.14))
		CreatureSculpt.limb(root, shoulder, elbow, 0.16, stone)
		MiniatureFactory.sphere(root, elbow, Vector3.ONE * 0.24, trim)
		CreatureSculpt.limb(root, elbow, Vector3(side * 0.46, 0.61, -0.14), 0.19, stone, 0.85)
		MiniatureFactory.box(root, Vector3(side * 0.46, 0.57, -0.16), Vector3(0.30, 0.27, 0.31), stone.darkened(0.12))
		if large:
			MiniatureFactory.box(root, shoulder + Vector3(side * 0.03, 0.15, 0), Vector3(0.36, 0.14, 0.41), trim)
			CreatureSculpt.limb(root, shoulder + Vector3(side * 0.10, 0.19, 0), shoulder + Vector3(side * 0.21, 0.37, 0), 0.09, trim, 0.1)
		MiniaturePose.attach(root, pivot, first)
	var chest := MiniatureFactory.sphere(root, Vector3(0, 0.92, 0), Vector3(0.67, 0.68, 0.44), stone)
	chest.rotation.x = -0.05
	MiniatureFactory.cylinder(root, Vector3(0, 0.67, 0), 0.28, 0.24, 0.16, trim).scale.z = 0.7
	var bezel := MiniatureFactory.cylinder(root, Vector3(0, 0.99, -0.21), 0.17, 0.20, 0.08, trim)
	bezel.rotation.x = PI * 0.5
	var core := MiniatureFactory.sphere(root, Vector3(0, 0.99, -0.27), Vector3(0.22, 0.24, 0.12), light)
	var core_mat: StandardMaterial3D = core.material_override
	core_mat.emission_enabled = true
	core_mat.emission = light * 0.65
	var head := MiniatureFactory.cylinder(root, Vector3(0, 1.40, 0), 0.16, 0.23, 0.34, stone.lightened(0.15))
	head.scale.z = 0.8
	MiniatureFactory.box(root, Vector3(0, 1.42, -0.18), Vector3(0.30, 0.075, 0.07), Color(0.10, 0.14, 0.17))
	for x: float in [-0.085, 0.085]:
		CreatureSculpt.eye(root, Vector3(x, 1.42, -0.228), light)
	for i in 3:
		MiniatureFactory.box(root, Vector3(0, 0.80 + i * 0.07, -0.23), Vector3(0.09 + i * 0.03, 0.022, 0.035), trim)
	if small:
		var fin := MiniatureFactory.sphere(root, Vector3(0, 1.59, 0.01), Vector3(0.11, 0.18, 0.12), trim)
		WeaponSculpt.metal(fin)
	root.scale = Vector3.ONE * (0.75 if small else (1.42 if large else 1.0))
