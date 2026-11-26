class_name CreatureSculpt
extends RefCounted
## Original stylized silhouettes with low polygon counts for mobile tabletop play.
const FROST := Color(0.72, 0.83, 0.87)
const DARK := Color(0.15, 0.19, 0.24)
const IVORY := Color(0.92, 0.86, 0.68)
const ICE := Color(0.32, 0.80, 0.96)


static func limb(root: Node3D, a: Vector3, b: Vector3, radius: float, color: Color, taper: float = 0.75) -> MeshInstance3D:
	var m := MiniatureFactory.cylinder(root, (a + b) * 0.5, radius * taper, radius, a.distance_to(b), color)
	var direction := (b - a).normalized()
	var axis := Vector3.UP.cross(direction)
	if axis.length() > 0.0001:
		m.quaternion = Quaternion(axis.normalized(), acos(clampf(Vector3.UP.dot(direction), -1.0, 1.0)))
	elif direction.y < 0.0:
		m.rotation.x = PI
	return m


static func eye(root: Node3D, at: Vector3, color: Color = ICE) -> void:
	var m := MiniatureFactory.sphere(root, at, Vector3.ONE * 0.075, color)
	var mat: StandardMaterial3D = m.material_override
	mat.emission_enabled = true
	mat.emission = color * 0.8


static func create(root: Node3D, f: Figure, faction: Color) -> bool:
	match f.def.id:
		"skeleton", "armoured_skeleton", "skeleton_archer":
			skeleton(root, f)
		"wraith":
			spirit(root, false)
		"genie":
			spirit(root, true)
		"ice_spider":
			spider(root)
		"ice_toad":
			toad(root)
		"white_gorilla", "werewolf", "snow_troll", "frost_giant":
			brute(root, f)
		"wolf", "wild_dog", "war_hound", "giant_rat", "snow_leopard", "bear", "boar":
			BeastSculpt.create(root,f,faction)
		_:
			return false
	return true


static func skeleton(root: Node3D, f: Figure) -> void:
	var armored := f.def.id == "armoured_skeleton"
	var metal := Color(0.32, 0.42, 0.48)
	for x: float in [-0.15, 0.15]:
		limb(root, Vector3(x, 0.11, -0.03), Vector3(x * 0.8, 0.63, 0), 0.065, IVORY)
		MiniatureFactory.sphere(root, Vector3(x, 0.10, -0.10), Vector3(0.14, 0.12, 0.27), IVORY)
		limb(root, Vector3(x * 1.9, 1.11, 0), Vector3(x * 2.5, 0.72, -0.13), 0.055, IVORY)
	MiniatureFactory.sphere(root, Vector3(0, 0.63, 0), Vector3(0.40, 0.24, 0.26), IVORY)
	limb(root, Vector3(0, 0.64, 0.03), Vector3(0, 1.22, 0.03), 0.075, IVORY)
	for i in 4:
		var y := 0.83 + i * 0.095
		var rib := TorusMesh.new()
		rib.inner_radius = 0.16
		rib.outer_radius = 0.22
		MiniatureFactory.mesh(root, rib, Vector3(0, y, -0.025), IVORY).scale = Vector3(1, 0.55, 0.63)
	MiniatureFactory.sphere(root, Vector3(0, 1.38, -0.04), Vector3(0.34, 0.36, 0.31), IVORY)
	for x: float in [-0.09, 0.09]:
		MiniatureFactory.sphere(root, Vector3(x, 1.40, -0.19), Vector3.ONE * 0.10, DARK)
		eye(root, Vector3(x, 1.40, -0.225), Color(0.68, 0.95, 0.57))
	MiniatureFactory.box(root, Vector3(0, 1.25, -0.12), Vector3(0.22, 0.11, 0.17), IVORY.darkened(0.13))
	if armored:
		MiniatureFactory.box(root, Vector3(0, 1.00, -0.15), Vector3(0.42, 0.33, 0.09), metal)
		MiniatureFactory.sphere(root, Vector3(0, 1.49, 0), Vector3(0.39, 0.20, 0.34), metal)
	MiniatureFactory.weapon(root, f)


static func spirit(root: Node3D, genie: bool) -> void:
	var cloth := Color(0.22, 0.48, 0.66) if genie else Color(0.16, 0.25, 0.36)
	for i in 5:
		var p := Vector3(sin(i * 0.8) * 0.12, 0.14 + i * 0.16, cos(i * 0.7) * 0.13)
		MiniatureFactory.sphere(root, p, Vector3(0.22 + i * 0.065, 0.32, 0.22 + i * 0.065), cloth.lightened(i * 0.04))
	MiniatureFactory.sphere(root, Vector3(0, 1.02, 0), Vector3(0.64, 0.63, 0.40), cloth)
	for x: float in [-1.0, 1.0]:
		limb(root, Vector3(x * 0.26, 1.13, 0), Vector3(x * 0.45, 1.0, -0.16), 0.16, cloth)
		limb(root, Vector3(x * 0.45, 1.0, -0.16), Vector3(x * 0.50, 1.28, -0.36), 0.11, cloth.lightened(0.14))
		if genie:
			MiniatureFactory.cylinder(root, Vector3(x * 0.46, 1.13, -0.25), 0.15, 0.14, 0.10, IVORY)
	MiniatureFactory.sphere(root, Vector3(0, 1.49, 0), Vector3(0.43, 0.47, 0.38), cloth.lightened(0.15))
	MiniatureFactory.sphere(root, Vector3(0, 1.45, -0.15), Vector3(0.28, 0.31, 0.15), DARK)
	for x: float in [-0.09, 0.09]:
		eye(root, Vector3(x, 1.49, -0.23), Color(1.0, 0.77, 0.30) if genie else ICE)
	if genie:
		MiniatureFactory.cylinder(root, Vector3(0, 1.70, 0), 0.14, 0.24, 0.16, IVORY)
		MiniatureFactory.sphere(root, Vector3(0, 1.74, -0.17), Vector3.ONE * 0.13, ICE)


static func spider(root: Node3D) -> void:
	MiniatureFactory.sphere(root, Vector3(0, 0.43, 0.14), Vector3(0.63, 0.58, 0.78), FROST.darkened(0.25))
	MiniatureFactory.sphere(root, Vector3(0, 0.39, -0.31), Vector3(0.42, 0.36, 0.42), DARK)
	for side: float in [-1.0, 1.0]:
		for i in 4:
			var z := -0.33 + i * 0.19
			var knee := Vector3(side * 0.55, 0.65, z * 1.4)
			limb(root, Vector3(side * 0.18, 0.42, z), knee, 0.07, FROST)
			limb(root, knee, Vector3(side * 0.75, 0.04, z * 1.8), 0.055, DARK, 0.3)
		eye(root, Vector3(side * 0.10, 0.45, -0.51))
		limb(root, Vector3(side * 0.13, 0.33, -0.47), Vector3(side * 0.07, 0.18, -0.59), 0.05, IVORY, 0.1)


static func toad(root: Node3D) -> void:
	var skin := Color(0.28, 0.50, 0.49)
	MiniatureFactory.sphere(root, Vector3(0, 0.35, 0.04), Vector3(0.85, 0.58, 0.82), skin)
	MiniatureFactory.sphere(root, Vector3(0, 0.37, -0.40), Vector3(0.76, 0.38, 0.44), skin.lightened(0.12))
	for x: float in [-0.29, 0.29]:
		MiniatureFactory.sphere(root, Vector3(x, 0.58, -0.40), Vector3.ONE * 0.21, skin)
		eye(root, Vector3(x, 0.60, -0.50), Color(0.96, 0.80, 0.30))
		MiniatureFactory.sphere(root, Vector3(x * 1.4, 0.22, 0.25), Vector3(0.30, 0.40, 0.55), skin.darkened(0.18))
		MiniatureFactory.box(root, Vector3(x * 1.5, 0.07, -0.32), Vector3(0.27, 0.08, 0.40), skin)


static func beast(root: Node3D, id: String) -> void:
	var fur := FROST.darkened(0.35) if id == "wolf" else (FROST if id == "snow_leopard" else Color(0.40, 0.27, 0.19))
	if id == "giant_rat":
		fur = Color(0.40, 0.39, 0.41)
	var bulk := 1.35 if id in ["bear", "boar"] else (0.7 if id == "giant_rat" else 1.0)
	MiniatureFactory.sphere(root, Vector3(0, 0.48 * bulk, 0.05), Vector3(0.52, 0.55, 0.89) * bulk, fur)
	MiniatureFactory.sphere(root, Vector3(0, 0.60 * bulk, -0.39 * bulk), Vector3(0.39, 0.39, 0.39) * bulk, fur)
	MiniatureFactory.sphere(root, Vector3(0, 0.52 * bulk, -0.63 * bulk), Vector3(0.24, 0.22, 0.38) * bulk, fur.darkened(0.28))
	for x: float in [-0.22, 0.22]:
		for z: float in [-0.25, 0.34]:
			limb(root, Vector3(x, 0.43, z) * bulk, Vector3(x * 1.12, 0.07, z - 0.06) * bulk, 0.10 * bulk, fur)
		MiniatureFactory.sphere(root, Vector3(x * 0.62, 0.83, -0.39) * bulk, Vector3(0.16, 0.21, 0.12) * bulk, fur)
		eye(root, Vector3(x * 0.55, 0.65, -0.57) * bulk, Color(0.94, 0.76, 0.34))
		if id == "boar":
			limb(root, Vector3(x * 0.57, 0.43, -0.75) * bulk, Vector3(x, 0.63, -0.84) * bulk, 0.065, IVORY, 0.05)
	var tail := Vector3(0.0, 0.52, 0.48) * bulk
	limb(root, tail, tail + Vector3(0.18, 0.20, 0.40 if id in ["giant_rat", "snow_leopard", "wolf"] else 0.17), 0.055 if id == "giant_rat" else 0.10, fur, 0.3)
	if id == "snow_leopard":
		for side: float in [-1.0, 1.0]:
			for i in 5:
				MiniatureFactory.sphere(root, Vector3(side * 0.255, 0.48 + sin(i * 2.1) * 0.12, -0.28 + i * 0.16), Vector3(0.035, 0.10, 0.10), DARK)


static func brute(root: Node3D, f: Figure) -> void:
	var fur := FROST if f.def.id in ["white_gorilla", "frost_giant"] else Color(0.38, 0.42, 0.40)
	var size := 1.4 if f.def.traits.has("large") else 1.0
	for x: float in [-0.18, 0.18]:
		limb(root, Vector3(x, 0.07, -0.04), Vector3(x, 0.65, 0), 0.15, fur.darkened(0.20))
		limb(root, Vector3(x * 1.7, 1.16, 0), Vector3(x * 2.65, 0.71, -0.08), 0.18, fur)
		limb(root, Vector3(x * 2.65, 0.71, -0.08), Vector3(x * 2.4, 0.34, -0.21), 0.15, fur.darkened(0.10))
	MiniatureFactory.sphere(root, Vector3(0, 0.92, 0), Vector3(0.77, 0.80, 0.51), fur)
	MiniatureFactory.sphere(root, Vector3(0, 1.42, -0.08), Vector3(0.43, 0.42, 0.39), fur.darkened(0.16))
	MiniatureFactory.sphere(root, Vector3(0, 1.33, -0.28), Vector3(0.29, 0.20, 0.29), DARK)
	for x: float in [-0.10, 0.10]:
		eye(root, Vector3(x, 1.47, -0.28))
		if f.def.id == "werewolf":
			MiniatureFactory.cylinder(root, Vector3(x * 1.5, 1.69, -0.07), 0.012, 0.09, 0.23, fur)
	if f.def.id == "frost_giant":
		MiniatureFactory.box(root, Vector3(0, 0.77, -0.26), Vector3(0.64, 0.30, 0.12), Color(0.24, 0.38, 0.50))
		limb(root, Vector3(0.47, 0.38, -0.17), Vector3(0.68, 1.48, -0.14), 0.10, DARK)
		MiniatureFactory.box(root, Vector3(0.68, 1.47, -0.14), Vector3(0.38, 0.39, 0.35), ICE.darkened(0.20))
	root.scale = Vector3.ONE * size
