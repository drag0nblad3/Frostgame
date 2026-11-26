class_name WarbandSculpt
extends RefCounted
## Distinct equipment silhouettes for the existing warband roles.
const GOLD := Color(0.78, 0.62, 0.29)
const STEEL := Color(0.57, 0.65, 0.69)
const HIDE := Color(0.28, 0.19, 0.13)


static func decorate(root: Node3D, f: Figure, color: Color) -> void:
	var id := f.def.id
	if id in ["wizard", "apprentice"]:
		MiniatureFactory.box(root, Vector3(-0.18, 0.70, -0.19), Vector3(0.16, 0.21, 0.10), HIDE)
		MiniatureFactory.box(root, Vector3(0.0, 0.73, -0.24), Vector3(0.12, 0.10, 0.04), GOLD)
		if id == "wizard":
			MiniatureFactory.sphere(root, Vector3(0, 1.15, -0.16), Vector3(0.21, 0.33, 0.17), Color(0.82, 0.84, 0.82))
		return
	if id in ["knight", "templar", "marksman", "man_at_arms", "infantryman"]:
		for x: float in [-0.31, 0.31]:
			MiniatureFactory.sphere(root, Vector3(x, 1.12, 0), Vector3(0.28, 0.23, 0.31), STEEL)
			MiniatureFactory.box(root, Vector3(x * 0.45, 0.38, -0.11), Vector3(0.19, 0.27, 0.08), STEEL)
		MiniatureFactory.box(root, Vector3(0, 0.97, -0.19), Vector3(0.14, 0.38, 0.06), color)
		if id == "templar":
			MiniatureFactory.box(root, Vector3(0, 1.05, -0.23), Vector3(0.30, 0.07, 0.05), GOLD)
		if id == "knight":
			MiniatureFactory.box(root, Vector3(0, 1.58, 0), Vector3(0.09, 0.18, 0.32), color.lightened(0.18))
	elif id in ["ranger", "tracker", "thief", "treasure_hunter", "archer"]:
		ClothSculpt.hood(root, color.darkened(0.55))
		ClothSculpt.cape(root, color.darkened(0.45), 0.72, 0.27)
		MiniatureFactory.box(root, Vector3(0.18, 0.66, -0.16), Vector3(0.18, 0.20, 0.13), HIDE)
		if f.ranged != null:
			CreatureSculpt.limb(root, Vector3(0.23, 0.68, 0.20), Vector3(0.12, 1.36, 0.26), 0.10, HIDE, 1.0)
	elif id == "barbarian":
		for x: float in [-0.22, 0.22]:
			MiniatureFactory.sphere(root, Vector3(x, 1.15, 0), Vector3(0.30, 0.28, 0.36), HIDE.lightened(0.35))
		MiniatureFactory.box(root, Vector3(0, 0.56, -0.09), Vector3(0.47, 0.35, 0.30), HIDE)
	elif id == "apothecary":
		for i in 3:
			var x := -0.18 + i * 0.18
			MiniatureFactory.sphere(root, Vector3(x, 0.72, -0.22), Vector3(0.12, 0.17, 0.12), Color(0.40, 0.83, 0.55) if i % 2 == 0 else Color(0.54, 0.69, 0.95))
			MiniatureFactory.cylinder(root, Vector3(x, 0.82, -0.22), 0.035, 0.035, 0.05, HIDE)
	elif id == "vampire":
		ClothSculpt.cape(root, Color(0.25, 0.06, 0.10), 1.03, 0.37)
		MiniatureFactory.box(root, Vector3(0, 1.32, 0.20), Vector3(0.57, 0.23, 0.09), Color(0.11, 0.10, 0.15))
