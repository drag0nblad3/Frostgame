class_name SchoolArt
extends RefCounted
## Original school-specific color schemes and ornaments. Base rings retain team color.
const PALETTES := {
	"chronomancer": ["34445d", "b4a46b", "a8ddf0"],
	"elementalist": ["834334", "d49a51", "ff9a39"],
	"enchanter": ["265a52", "c6a05c", "9be0b7"],
	"illusionist": ["594274", "c6b1dc", "d9a5ff"],
	"necromancer": ["30383a", "b9c7a0", "86e6a0"],
	"sigilist": ["5a3532", "dbbe88", "ffd38a"],
	"soothsayer": ["2d536c", "acb9c8", "83d5f4"],
	"summoner": ["63384b", "b7754a", "ed8da9"],
	"thaumaturge": ["c2c4af", "b79349", "fff0b0"],
	"witch": ["4c5936", "ad9b70", "c2df77"]
}


static func of_figure(f: Figure) -> String:
	if f.battle_ref != null:
		var s := f.battle_ref.get_ref() as GameState
		if s != null:
			return str(s.side_schools.get(f.original_side, ""))
	return ""


static func cloth(school: String, fallback: Color) -> Color:
	return Color(PALETTES[school][0]) if PALETTES.has(school) else fallback


static func accent(school: String) -> Color:
	return Color(PALETTES[school][1]) if PALETTES.has(school) else Color(0.76,0.59,0.27)


static func glow(school: String) -> Color:
	return Color(PALETTES[school][2]) if PALETTES.has(school) else Color(0.38,0.83,1.0)


static func dress(root: Node3D, school: String, apprentice: bool) -> void:
	if not PALETTES.has(school):
		return
	var trim := accent(school)
	var color := cloth(school, Color.WHITE)
	var gem := glow(school)
	# A shared school insignia on the chest, independent of the selected weapon.
	var pin := MiniatureFactory.sphere(root, Vector3(0,1.04,-0.195),Vector3(0.115,0.145,0.075),trim)
	WeaponSculpt.metal(pin)
	CreatureSculpt.eye(root,Vector3(0,1.04,-0.245),gem)
	match school:
		"chronomancer":
			for y: float in [0.57,0.70]:
				var disc := MiniatureFactory.cylinder(root,Vector3(-0.20,y,-0.21),0.095,0.095,0.035,trim)
				disc.rotation.x = PI*0.5
			CreatureSculpt.limb(root,Vector3(-0.27,0.69,-0.24),Vector3(-0.13,0.58,-0.24),0.025,gem,1.0)
		"elementalist":
			for side: float in [-1.0,1.0]:
				for i in 2:
					var a := Vector3(side*(0.18+i*0.08),1.12,0.045)
					CreatureSculpt.limb(root,a,a+Vector3(side*0.025,0.17-i*0.045,-0.03),0.045,gem,0.0)
		"enchanter":
			for i in 3:
				var x := (i-1)*0.13
				WeaponSculpt.metal(MiniatureFactory.box(root,Vector3(x,0.72,-0.23),Vector3(0.085,0.095,0.065),trim))
		"illusionist":
			for side: float in [-1.0,1.0]:
				var a := Vector3(side*0.22,1.38,0.06)
				CreatureSculpt.limb(root,a,a+Vector3(side*0.09,0.22,0.16),0.045,trim,0.06)
		"necromancer":
			MiniatureFactory.sphere(root,Vector3(-0.20,0.69,-0.23),Vector3(0.19,0.22,0.17),Color(0.89,0.84,0.69))
			for x: float in [-0.24,-0.16]:
				MiniatureFactory.sphere(root,Vector3(x,0.71,-0.31),Vector3.ONE*0.045,Color(0.08,0.11,0.10))
		"sigilist":
			MiniatureFactory.box(root,Vector3(0.18,0.80,-0.22),Vector3(0.22,0.31,0.12),trim)
			MiniatureFactory.box(root,Vector3(0.18,0.80,-0.292),Vector3(0.17,0.26,0.025),color)
			for i in 3:
				MiniatureFactory.box(root,Vector3(0.18,0.73+i*0.065,-0.31),Vector3(0.11,0.022,0.02),gem)
		"soothsayer":
			var orb := MiniatureFactory.sphere(root,Vector3(-0.24,0.78,-0.31),Vector3.ONE*0.19,gem)
			var mat: StandardMaterial3D = orb.material_override
			mat.emission_enabled = true
			mat.emission = gem*0.45
		"summoner":
			for side: float in [-1.0,1.0]:
				var a := Vector3(side*0.17,1.46,0.04)
				var b := a+Vector3(side*0.12,0.15,0.01)
				CreatureSculpt.limb(root,a,b,0.06,trim,0.6)
				CreatureSculpt.limb(root,b,b+Vector3(side*0.06,0.12,-0.08),0.035,trim,0.0)
		"thaumaturge":
			for side: float in [-1.0,1.0]:
				MiniatureFactory.box(root,Vector3(side*0.16,0.88,-0.18),Vector3(0.095,0.42,0.075),trim)
		"witch":
			for i in 3:
				var x := -0.18+i*0.17
				MiniatureFactory.sphere(root,Vector3(x,0.71,-0.235),Vector3(0.10,0.16,0.11),gem.darkened(i*0.13))
				MiniatureFactory.cylinder(root,Vector3(x,0.80,-0.235),0.034,0.035,0.045,trim)
	if not apprentice:
		var hem := MiniatureFactory.cylinder(root,Vector3(0,0.23,0),0.34,0.36,0.035,trim)
		hem.scale.z = 0.75
