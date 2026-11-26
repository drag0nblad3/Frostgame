class_name MonsterSculpt
extends RefCounted
## Sculpted undead and infernal miniatures with distinct poses and palettes.
const BONE := Color(0.84, 0.80, 0.65)
const SHADOW := Color(0.12, 0.13, 0.16)
const BRONZE := Color(0.58, 0.39, 0.19)


static func create(root: Node3D, f: Figure) -> bool:
	match f.def.id:
		"ghoul", "zombie":
			undead(root, f.def.id == "ghoul")
		"imp", "minor_demon", "major_demon":
			demon(root, f.def.id)
		"animated_skull":
			skull(root)
		"giant_worm":
			worm(root)
		_:
			return false
	return true


static func undead(root: Node3D, ghoul: bool) -> void:
	var skin := Color(0.49, 0.59, 0.49) if ghoul else Color(0.58, 0.61, 0.51)
	var cloth := Color(0.24, 0.25, 0.23) if ghoul else Color(0.38, 0.25, 0.19)
	var torso_y := 0.88 if ghoul else 0.94
	var head_y := 1.16 if ghoul else 1.30
	MiniatureFactory.sphere(root, Vector3(0, torso_y, -0.07), Vector3(0.49, 0.62, 0.36), skin if ghoul else cloth).rotation.x = -0.23
	MiniatureFactory.sphere(root, Vector3(0, 0.56, 0.02), Vector3(0.42, 0.30, 0.32), cloth)
	for side: float in [-1.0, 1.0]:
		var foot := Vector3(side * 0.22, 0.12, -0.10 if side > 0 else 0.19)
		var knee := Vector3(side * 0.21, 0.36, -0.11)
		CreatureSculpt.limb(root, Vector3(side * 0.13, 0.58, 0), knee, 0.105, cloth)
		CreatureSculpt.limb(root, knee, foot, 0.075, skin)
		MiniatureFactory.sphere(root, foot + Vector3(0, -0.035, -0.06), Vector3(0.17, 0.12, 0.27), skin)
		var pivot := MiniaturePose.arm(root, side > 0)
		var first := root.get_child_count()
		var shoulder := Vector3(side * 0.21, torso_y + 0.19, -0.10)
		var elbow := Vector3(side * 0.40, 0.77 if ghoul else 0.99, -0.29)
		var hand := Vector3(side * 0.38, 0.60 if ghoul else 0.93, -0.53)
		CreatureSculpt.limb(root, shoulder, elbow, 0.097, skin)
		CreatureSculpt.limb(root, elbow, hand, 0.071, skin, 0.8)
		MiniatureFactory.sphere(root, hand, Vector3(0.18, 0.13, 0.20), skin)
		for i in 3:
			var a := hand + Vector3((i - 1) * 0.05, -0.01, -0.07)
			CreatureSculpt.limb(root, a, a + Vector3(0, -0.06, -0.12 if ghoul else -0.06), 0.023, BONE if ghoul else skin, 0.2)
		MiniaturePose.attach(root, pivot, first)
	MiniatureFactory.sphere(root, Vector3(0, head_y, -0.25), Vector3(0.35, 0.40, 0.34), skin)
	MiniatureFactory.sphere(root, Vector3(0, head_y - 0.11, -0.39), Vector3(0.21, 0.13, 0.10), SHADOW)
	for x: float in [-0.075, 0.075]:
		CreatureSculpt.eye(root, Vector3(x, head_y + 0.03, -0.418), Color(0.82, 0.91, 0.46))
		MiniatureFactory.box(root, Vector3(x * 0.65, head_y - 0.08, -0.447), Vector3(0.04, 0.06, 0.035), BONE)
	if ghoul:
		for i in 5:
			var y := 0.66 + i * 0.10
			MiniatureFactory.sphere(root, Vector3(0, y, 0.13 + i * 0.01), Vector3(0.12, 0.09, 0.10), BONE.darkened(0.18))
	else:
		MiniatureFactory.sphere(root, Vector3(0, 1.38, -0.22), Vector3(0.36, 0.20, 0.32), SHADOW)
		MiniatureFactory.box(root, Vector3(-0.17, 0.89, -0.24), Vector3(0.12, 0.34, 0.04), cloth.lightened(0.28)).rotation.z = -0.14
		MiniatureFactory.box(root, Vector3(0.10, 0.66, -0.14), Vector3(0.27, 0.26, 0.12), cloth.darkened(0.2))


static func demon(root: Node3D, id: String) -> void:
	var major := id == "major_demon"
	var imp := id == "imp"
	var skin := Color(0.56, 0.20, 0.17) if imp else (Color(0.32, 0.22, 0.34) if major else Color(0.46, 0.23, 0.23))
	var horn := BONE.darkened(0.32)
	MiniatureFactory.sphere(root, Vector3(0, 0.90, 0), Vector3(0.62 if major else 0.47, 0.64, 0.42), skin)
	MiniatureFactory.sphere(root, Vector3(0, 0.60, 0.03), Vector3(0.40, 0.29, 0.34), skin.darkened(0.2))
	for side: float in [-1.0, 1.0]:
		var hoof := Vector3(side * 0.23, 0.08, -0.12)
		var knee := Vector3(side * 0.22, 0.36, -0.14)
		CreatureSculpt.limb(root, Vector3(side * 0.15, 0.62, 0.02), knee, 0.13, skin)
		CreatureSculpt.limb(root, knee, hoof, 0.10, skin.darkened(0.15))
		MiniatureFactory.sphere(root, hoof, Vector3(0.22, 0.18, 0.28), SHADOW)
		var pivot := MiniaturePose.arm(root, side > 0)
		var first := root.get_child_count()
		var shoulder := Vector3(side * 0.28, 1.11, 0)
		var elbow := Vector3(side * 0.44, 0.91, -0.08)
		var hand := Vector3(side * 0.47, 0.72, -0.33)
		CreatureSculpt.limb(root, shoulder, elbow, 0.13, skin)
		CreatureSculpt.limb(root, elbow, hand, 0.115, skin, 0.7)
		MiniatureFactory.sphere(root, hand, Vector3(0.21, 0.18, 0.20), skin)
		for i in 3:
			var a := hand + Vector3((i - 1) * 0.055, -0.03, -0.07)
			CreatureSculpt.limb(root, a, a + Vector3(side * 0.025, -0.09, -0.11), 0.034, horn, 0.05)
		if major:
			MiniatureFactory.sphere(root, shoulder, Vector3(0.34, 0.31, 0.36), SHADOW)
			CreatureSculpt.limb(root, shoulder + Vector3(side * 0.06, 0.10, 0), shoulder + Vector3(side * 0.18, 0.39, 0), 0.09, horn, 0.05)
		MiniaturePose.attach(root, pivot, first)
		var h := Vector3(side * 0.13, 1.44, 0.02)
		var bend := Vector3(side * 0.24, 1.63, 0.035)
		CreatureSculpt.limb(root, h, bend, 0.075, horn, 0.62)
		CreatureSculpt.limb(root, bend, Vector3(side * 0.31, 1.77 if major else 1.68, -0.08), 0.047, horn, 0.03)
	MiniatureFactory.sphere(root, Vector3(0, 1.30, -0.045), Vector3(0.39, 0.42, 0.35), skin.darkened(0.08))
	MiniatureFactory.sphere(root, Vector3(0, 1.23, -0.23), Vector3(0.26, 0.19, 0.25), skin.darkened(0.27))
	for x: float in [-0.09, 0.09]:
		CreatureSculpt.eye(root, Vector3(x, 1.34, -0.225), Color(1.0, 0.54, 0.20))
		CreatureSculpt.limb(root, Vector3(x * 0.7, 1.19, -0.31), Vector3(x * 0.7, 1.10, -0.33), 0.026, horn, 0.06)
	var tail := [Vector3(0, 0.55, 0.18), Vector3(0.17, 0.36, 0.42), Vector3(0.43, 0.42, 0.49), Vector3(0.48, 0.69, 0.40)]
	for i in range(1, tail.size()):
		CreatureSculpt.limb(root, tail[i - 1], tail[i], 0.08 - i * 0.012, skin, 0.75)
	CreatureSculpt.limb(root, tail[-1], tail[-1] + Vector3(-0.03, 0.18, -0.04), 0.075, horn, 0.0)
	if major:
		WeaponSculpt.metal(MiniatureFactory.sphere(root, Vector3(0, 0.95, -0.22), Vector3(0.43, 0.48, 0.13), BRONZE.darkened(0.30)))
		CreatureSculpt.eye(root, Vector3(0, 0.97, -0.30), Color(1.0, 0.42, 0.13))
	root.scale = Vector3.ONE * (1.35 if major else (0.65 if imp else 1.0))


static func skull(root: Node3D) -> void:
	MiniatureFactory.sphere(root, Vector3(0, 0.94, 0), Vector3(0.56, 0.60, 0.50), BONE)
	MiniatureFactory.sphere(root, Vector3(0, 0.71, -0.10), Vector3(0.33, 0.20, 0.34), BONE.darkened(0.18))
	for x: float in [-0.13, 0.13]:
		MiniatureFactory.sphere(root, Vector3(x, 0.96, -0.22), Vector3(0.18, 0.17, 0.12), SHADOW)
		CreatureSculpt.eye(root, Vector3(x, 0.96, -0.28), Color(0.54, 0.94, 0.75))
	MiniatureFactory.sphere(root, Vector3(0, 0.84, -0.246), Vector3(0.08, 0.09, 0.07), SHADOW)
	for i in 5:
		MiniatureFactory.box(root, Vector3((i - 2) * 0.056, 0.74, -0.27), Vector3(0.044, 0.06, 0.06), BONE)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.21
	ring.outer_radius = 0.27
	var glow := MiniatureFactory.mesh(root, ring, Vector3(0, 0.47, 0), Color(0.36, 0.65, 0.65))
	glow.scale.y = 0.35


static func worm(root: Node3D) -> void:
	var hide := Color(0.45, 0.38, 0.33)
	var spine: Array[Vector3] = []
	for i in 9:
		var t := float(i) / 8.0
		spine.append(Vector3(sin(t * PI) * 0.32, 0.20 + t * 1.57, 0.22 - t * t * 0.57))
	for i in spine.size():
		var t := float(i) / 8.0
		var radius := 0.38 - t * 0.105
		MiniatureFactory.sphere(root, spine[i], Vector3(radius * 2, 0.37, radius * 1.88), hide.lightened(0.18 * t))
		var band := TorusMesh.new()
		band.inner_radius = radius * 0.90
		band.outer_radius = radius * 1.03
		MiniatureFactory.mesh(root, band, spine[i], hide.darkened(0.25)).scale.y = 0.45
	var mouth := spine[-1] + Vector3(0, 0.04, -0.23)
	MiniatureFactory.sphere(root, mouth, Vector3(0.47, 0.47, 0.14), SHADOW)
	var rim := TorusMesh.new()
	rim.inner_radius = 0.18
	rim.outer_radius = 0.29
	MiniatureFactory.mesh(root, rim, mouth + Vector3(0, 0, -0.045), hide.lightened(0.28)).rotation.x = PI * 0.5
	for i in 10:
		var angle := TAU * i / 10.0
		var outer := mouth + Vector3(cos(angle) * 0.21, sin(angle) * 0.21, -0.09)
		var inner := mouth + Vector3(cos(angle) * 0.12, sin(angle) * 0.12, -0.14)
		CreatureSculpt.limb(root, outer, inner, 0.038, BONE, 0.0)
