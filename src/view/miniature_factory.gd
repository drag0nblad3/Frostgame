class_name MiniatureFactory
extends RefCounted
## Original low-poly tabletop miniatures. Purely visual, no collision bodies.

const IRON := Color(0.38, 0.44, 0.50)
const LEATHER := Color(0.30, 0.21, 0.17)
const BONE := Color(0.85, 0.82, 0.69)
const SKIN := Color(0.78, 0.61, 0.46)


static func create(f: Figure, faction: Color) -> Node3D:
	var model := Node3D.new()
	var color := faction
	if CreatureSculpt.create(model, f, faction):
		return model
	if f.def.traits.has("construct"):
		construct(model, faction, 1.25 if f.def.traits.has("large") else 1.0)
	elif f.def.id == "giant_worm":
		worm(model)
	elif f.def.id == "animated_skull":
		sphere(model, Vector3(0, 1.0, 0), Vector3(0.48, 0.52, 0.46), BONE)
		for x: float in [-0.10, 0.10]:
			sphere(model, Vector3(x, 1.06, -0.21), Vector3.ONE * 0.10, Color(0.1, 0.12, 0.18))
	elif f.def.traits.has("animal"):
		animal(model, f.def.id)
	else:
		var caster := f.def.role in ["wizard", "apprentice"]
		var undead := f.def.traits.has("undead")
		var demon := f.def.traits.has("demon")
		var large := f.def.traits.has("large")
		var skin := BONE if undead else (Color(0.62, 0.24, 0.26) if demon else SKIN)
		var coat := Color(0.29, 0.38, 0.45) if undead else faction.darkened(0.30)
		var metal := f.def.armour >= 11 and not caster
		for x: float in [-0.13, 0.13]:
			box(model, Vector3(x, 0.25, 0), Vector3(0.19, 0.35, 0.22), LEATHER)
			box(model, Vector3(x, 0.10, -0.045), Vector3(0.21, 0.17, 0.30), LEATHER.darkened(0.25))
		cylinder(model, Vector3(0, 0.57, 0), 0.22, 0.34 if caster else 0.25, 0.55, coat)
		box(model, Vector3(0, 0.93, 0), Vector3(0.48, 0.46, 0.32), IRON if metal else coat)
		box(model, Vector3(0, 0.72, -0.18), Vector3(0.50, 0.085, 0.09), LEATHER)
		for x: float in [-0.30, 0.30]:
			box(model, Vector3(x, 0.92, 0), Vector3(0.16, 0.36, 0.18), IRON if metal else coat)
			sphere(model, Vector3(x, 0.75, -0.07), Vector3.ONE * 0.14, skin)
		sphere(model, Vector3(0, 1.30, -0.015), Vector3(0.32, 0.38, 0.31), skin)
		if caster:
			cylinder(model, Vector3(0, 1.50, 0), 0.10, 0.24, 0.26, faction.darkened(0.40))
			cylinder(model, Vector3(0, 1.42, 0), 0.31, 0.31, 0.055, faction.darkened(0.35))
			box(model, Vector3(0, 0.80, 0.19), Vector3(0.55, 0.90, 0.09), faction)
		elif metal:
			sphere(model, Vector3(0, 1.36, 0.015), Vector3(0.38, 0.34, 0.35), IRON)
			box(model, Vector3(0, 1.31, -0.18), Vector3(0.28, 0.075, 0.07), Color(0.08, 0.12, 0.16))
		elif undead:
			for x: float in [-0.08, 0.08]:
				sphere(model, Vector3(x, 1.33, -0.16), Vector3.ONE * 0.07, Color(0.06, 0.10, 0.15))
		if demon:
			for x: float in [-0.14, 0.14]:
				cylinder(model, Vector3(x, 1.53, 0), 0.015, 0.08, 0.28, BONE.darkened(0.35))
		WarbandSculpt.decorate(model, f, faction)
		weapon(model, f)
		if large:
			model.scale = Vector3(1.23, 1.35, 1.23)
		if f.def.traits.has("ethereal"):
			model.position.y += 0.15
	return model


static func weapon(model: Node3D, f: Figure) -> void:
	var id := f.melee.id if f.melee != null else ""
	match id:
		"staff":
			cylinder(model, Vector3(0.39, 0.92, -0.06), 0.045, 0.045, 1.70, LEATHER.lightened(0.15))
			sphere(model, Vector3(0.39, 1.79, -0.06), Vector3.ONE * 0.17, Color(0.40, 0.83, 0.94))
		"hand_weapon", "two_handed", "dagger":
			var length := 1.1 if id == "two_handed" else (0.35 if id == "dagger" else 0.76)
			box(model, Vector3(0.39, 0.77 + length * 0.5, -0.07), Vector3(0.095, length, 0.045), IRON.lightened(0.35))
			box(model, Vector3(0.39, 0.82, -0.07), Vector3(0.23, 0.065, 0.09), LEATHER)
	if f.ranged != null:
		if f.ranged.id == "bow":
			var points := [Vector3(-0.39, 0.37, -0.18), Vector3(-0.53, 0.58, -0.18), Vector3(-0.58, 0.91, -0.18), Vector3(-0.53, 1.24, -0.18), Vector3(-0.39, 1.45, -0.18)]
			for i in range(1, points.size()):
				CreatureSculpt.limb(model, points[i - 1], points[i], 0.035, LEATHER.lightened(0.25), 1.0)
			CreatureSculpt.limb(model, points[0], points[-1], 0.010, BONE, 1.0)
		else:
			box(model, Vector3(-0.38, 0.85, -0.19), Vector3(0.11, 0.10, 0.60), LEATHER)
			box(model, Vector3(-0.38, 0.88, -0.37), Vector3(0.65, 0.06, 0.10), IRON)
	if f.def.shield:
		cylinder(model, Vector3(-0.31, 0.84, -0.22), 0.24, 0.24, 0.085, IRON).rotation.x = PI * 0.5


static func construct(model: Node3D, faction: Color, size: float) -> void:
	for x: float in [-0.19, 0.19]:
		box(model, Vector3(x, 0.32, 0), Vector3(0.28, 0.60, 0.29), IRON.darkened(0.15))
		box(model, Vector3(x * 1.95, 0.85, 0), Vector3(0.27, 0.62, 0.33), IRON)
	box(model, Vector3(0, 0.89, 0), Vector3(0.61, 0.66, 0.39), IRON)
	box(model, Vector3(0, 1.40, 0), Vector3(0.36, 0.34, 0.32), IRON.lightened(0.15))
	box(model, Vector3(0, 1.41, -0.17), Vector3(0.26, 0.065, 0.035), faction.lightened(0.45))
	model.scale = Vector3.ONE * size


static func animal(model: Node3D, id: String) -> void:
	var fur := Color(0.55, 0.60, 0.65) if id in ["wolf", "snow_leopard", "ice_spider"] else LEATHER.lightened(0.20)
	var legs := 8 if id == "ice_spider" else 4
	sphere(model, Vector3(0, 0.49, 0.04), Vector3(0.55, 0.58, 0.79), fur)
	sphere(model, Vector3(0, 0.57, -0.40), Vector3(0.36, 0.38, 0.40), fur.lightened(0.1))
	for i in legs:
		var x := -0.23 if i % 2 == 0 else 0.23
		var z := -0.23 + floori(i / 2.0) * (0.15 if legs == 8 else 0.46)
		box(model, Vector3(x, 0.20, z), Vector3(0.13, 0.38, 0.16), fur.darkened(0.12))
	if id not in ["ice_spider", "ice_toad"]:
		for x: float in [-0.11, 0.11]:
			cylinder(model, Vector3(x, 0.80, -0.38), 0.015, 0.09, 0.24, fur)
	if id == "bear":
		model.scale = Vector3.ONE * 1.25


static func worm(model: Node3D) -> void:
	for i in 6:
		var p := Vector3(sin(i * 0.4) * 0.24, 0.24 + i * 0.20, cos(i * 0.4) * 0.24)
		sphere(model, p, Vector3.ONE * (0.62 - i * 0.035), Color(0.59, 0.39, 0.30).lightened(i * 0.025))
	sphere(model, Vector3(0.24, 1.38, -0.1), Vector3(0.32, 0.32, 0.32), Color(0.11, 0.09, 0.12))


static func mesh(model: Node3D, shape: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.position = pos
	node.material_override = BoardView._mat(color, 0.78)
	model.add_child(node)
	return node


static func box(model: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return mesh(model, shape, pos, color)


static func sphere(model: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	shape.radial_segments = 8
	shape.rings = 5
	var node := mesh(model, shape, pos, color)
	node.scale = size
	return node


static func cylinder(model: Node3D, pos: Vector3, top: float, bottom: float, height: float, color: Color) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = top
	shape.bottom_radius = bottom
	shape.height = height
	shape.radial_segments = 10
	return mesh(model, shape, pos, color)
