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
			BoneSculpt.create(root,f)
		"wraith":
			SpiritSculpt.wraith(root)
		"genie":
			SpiritSculpt.genie(root)
		"ice_spider":
			IceBeastSculpt.spider(root)
		"ice_toad":
			IceBeastSculpt.toad(root)
		"white_gorilla", "werewolf", "snow_troll", "frost_giant":
			BruteSculpt.create(root,f)
		"wolf", "wild_dog", "war_hound", "giant_rat", "snow_leopard", "bear", "boar":
			BeastSculpt.create(root,f,faction)
		_:
			return false
	return true

