class_name MiniatureMotion
extends RefCounted
## Visual-only motion profiles. The controller and event duration remain unchanged.


static func profile(f: Figure) -> String:
	var id := f.def.id
	if id in ["genie","wraith","animated_skull"]:
		return "float"
	if id=="ice_spider":
		return "spider"
	if id=="ice_toad":
		return "hop"
	if id=="giant_worm":
		return "slither"
	if id in ["wolf","wild_dog","war_hound","snow_leopard","giant_rat"]:
		return "trot"
	if id in ["bear","boar","white_gorilla","snow_troll","frost_giant","large_construct","major_demon"]:
		return "heavy"
	return "walk"


static func frequency(kind: String) -> float:
	match kind:
		"heavy": return 12.0
		"trot","spider": return 24.0
		"float","slither": return 8.0
		"hop": return 13.0
		_: return 17.0


static func reset(root: Node3D) -> void:
	MiniaturePose.arms(root,0,0)
	for i in 8:
		var leg := root.get_node_or_null("Leg%d"%i) as Node3D
		if leg!=null:
			leg.rotation=Vector3.ZERO
	for name: String in ["RightArm","LeftArm"]:
		var arm := root.get_node_or_null(name) as Node3D
		if arm!=null:
			arm.rotation=Vector3.ZERO


static func travel(root: Node3D,kind: String,phase: float,rest: float,running: bool=false) -> void:
	var wave := sin(phase)
	var opposite := cos(phase)
	root.position.y=rest
	root.rotation.x=0
	root.rotation.z=0
	match kind:
		"float":
			root.position.y=rest+0.05+0.045*wave
			root.rotation.z=0.04*opposite
			MiniaturePose.arms(root,0.08*wave,-0.08*wave)
		"slither":
			root.rotation.z=0.11*wave
			root.rotation.x=0.08*opposite
		"hop":
			root.position.y=rest+0.18*pow(maxf(0.0,wave),2.0)
			root.rotation.x=0.10*opposite
		"spider":
			root.position.y=rest+0.025*absf(wave)
			for i in 8:
				var leg := root.get_node_or_null("Leg%d"%i) as Node3D
				if leg!=null:
					var swing := sin(phase+PI*((i+floori(float(i)/4.0))%2))
					leg.rotation.x=0.21*swing
					leg.rotation.z=0.10*maxf(0.0,swing)*(-1.0 if i<4 else 1.0)
		"trot","heavy":
			var amp := (0.22 if kind=="heavy" else 0.42)*(1.20 if running else 1.0)
			root.position.y=rest+0.035*absf(wave)
			root.rotation.x=0.04*opposite
			root.rotation.z=0.035*wave
			if root.has_node("Leg3"):
				MiniaturePose.legs(root,[amp*wave,-amp*wave,-amp*wave,amp*wave])
			else:
				MiniaturePose.legs(root,[amp*wave,-amp*wave])
				MiniaturePose.arms(root,-0.16*wave,0.16*wave)
		_:
			var amp := 0.43 if running else 0.30
			root.position.y=rest+(0.065 if running else 0.045)*absf(wave)
			root.rotation.x=-0.12 if running else -0.055
			root.rotation.z=0.028*wave
			MiniaturePose.legs(root,[amp*wave,-amp*wave])
			MiniaturePose.arms(root,-amp*0.92*wave,amp*0.92*wave)


static func action(root: Node3D,kind: String,act: String,amount: float,rest: float,weapon: String) -> void:
	var t := clampf(amount,-0.45 if act=="attack" else 0.0,1.0)
	reset(root)
	root.position.y=rest
	root.rotation.x=0
	root.rotation.z=0
	match act:
		"attack":
			root.rotation.x=-0.22*t
			if kind in ["trot","spider","hop","slither"]:
				root.position.y=rest+0.08*maxf(0.0,t)
				root.rotation.x=-0.32*t
				MiniaturePose.legs(root,[-0.25*t,0.15*t,-0.25*t,0.15*t])
			else:
				var two := weapon in ["two_handed","staff"]
				MiniaturePose.arms(root,-1.12*t,-0.73*t if two else 0.24*t)
				root.rotation.z=0.08*t
		"cast":
			root.position.y=rest+0.075*t
			root.rotation.x=-0.08*t
			MiniaturePose.arms(root,-0.78*t,-1.02*t)
		"shot":
			root.rotation.x=-0.05*t
			MiniaturePose.arms(root,-0.48*t if weapon=="crossbow" else -0.38*t,-1.05*t)
		"recoil":
			root.rotation.x=0.25*t
			root.rotation.z=-0.07*t
			MiniaturePose.arms(root,0.28*t,0.36*t)
