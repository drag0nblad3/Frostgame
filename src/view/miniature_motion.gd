class_name MiniatureMotion
extends RefCounted
## Visual-only motion profiles. The controller and event duration remain unchanged.


static func profile(f: Figure) -> String:
	var id := f.def.id
	if id in ["genie","wraith","animated_skull","mindshrike","red_king_herald","herald_of_the_red_king","hrut_stinger"]:
		return "float"
	if id in ["zombie","burning_man","nullman"]:
		return "shamble"
	if id in ["ghoul","werewolf","blood_marked_berserker"]:
		return "stalk"
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
		"heavy","shamble": return 12.0
		"stalk": return 19.0
		"trot","spider": return 24.0
		"float","slither": return 8.0
		"hop": return 13.0
		_: return 17.0


static func reset(root: Node3D) -> void:
	MiniaturePose.arms(root,0,0)
	MiniaturePose.bend_arms(root,0,0)
	SecondaryMotion.reset(root)
	for name: String in ["Head","Tail"]:
		var part := root.get_node_or_null(name) as Node3D
		if part!=null:
			part.rotation=Vector3.ZERO
	for i in 8:
		var leg := root.get_node_or_null("Leg%d"%i) as Node3D
		if leg!=null:
			leg.rotation=Vector3.ZERO
		MiniaturePose.bend_leg(root,i,0)
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
			var lift := maxf(0.0,wave)
			root.position.y=rest+0.24*lift*lift
			root.rotation.x=0.13*opposite
			MiniaturePose.legs(root,[-0.34*lift,0.52*lift,-0.34*lift,0.52*lift])
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
				for i in 4:
					var w := wave if i in [0,3] else -wave
					MiniaturePose.bend_leg(root,i,0.45*maxf(0.0,-w))
				_animate_beast(root,wave,opposite)
			else:
				MiniaturePose.legs(root,[amp*wave,-amp*wave])
				MiniaturePose.arms(root,-0.16*wave,0.16*wave)
				MiniaturePose.bend_arms(root,-0.22*maxf(0.0,wave),-0.22*maxf(0.0,-wave))
				MiniaturePose.bend_leg(root,0,0.32*maxf(0.0,wave))
				MiniaturePose.bend_leg(root,1,0.32*maxf(0.0,-wave))
		"shamble":
			root.position.y=rest+0.026*absf(wave)
			root.rotation.z=0.065*wave
			root.rotation.x=-0.10
			MiniaturePose.legs(root,[0.17*wave,-0.25*wave])
			MiniaturePose.arms(root,-0.16+0.09*wave,-0.13-0.07*wave)
		_:
			var amp := (0.50 if running else 0.36) if kind=="stalk" else (0.43 if running else 0.30)
			root.position.y=rest+(0.065 if running else 0.045)*absf(wave)
			root.rotation.x=-0.12 if running else -0.055
			root.rotation.z=0.028*wave
			MiniaturePose.legs(root,[amp*wave,-amp*wave])
			MiniaturePose.arms(root,-amp*0.92*wave,amp*0.92*wave)
			MiniaturePose.bend_arms(root,-0.25*maxf(0.0,wave),-0.25*maxf(0.0,-wave))
			MiniaturePose.bend_leg(root,0,(0.62 if running else 0.42)*maxf(0.0,wave))
			MiniaturePose.bend_leg(root,1,(0.62 if running else 0.42)*maxf(0.0,-wave))

	SecondaryMotion.travel(root,kind,phase,running)


static func action(root: Node3D,kind: String,act: String,amount: float,rest: float,weapon: String) -> void:
	var t := clampf(amount,-0.45 if act=="attack" else 0.0,1.0)
	reset(root)
	root.position.y=rest
	root.rotation.x=0
	root.rotation.z=0
	match act:
		"attack":
			root.rotation.x=-0.22*t
			if root.has_node("Leg3") or kind in ["trot","spider","hop","slither"]:
				root.position.y=rest+0.08*maxf(0.0,t)
				root.rotation.x=-0.32*t
				MiniaturePose.legs(root,[-0.25*t,0.15*t,-0.25*t,0.15*t])
				var head := root.get_node_or_null("Head") as Node3D
				if head!=null:
					head.rotation.x=0.22*t
			else:
				var two := weapon in ["two_handed","staff"]
				MiniaturePose.arms(root,-1.05*t,-0.78*t if two else 0.28*t)
				SecondaryMotion.arm_spread(root,0.20*t,-0.12*t if two else -0.22*t)
				MiniaturePose.bend_arms(root,-0.38*t,-0.36*t if two else -0.18*absf(t))
				MiniaturePose.legs(root,[-0.11*t,0.18*t])
				MiniaturePose.bend_leg(root,1,0.20*absf(t))
				root.rotation.z=0.08*t
		"cast":
			root.position.y=rest+0.075*t
			root.rotation.x=-0.08*t
			MiniaturePose.arms(root,-0.85*t,-1.02*t)
			SecondaryMotion.arm_spread(root,0.25*t,-0.32*t)
			MiniaturePose.bend_arms(root,-0.33*t,-0.43*t)
		"shot":
			root.rotation.x=-0.05*t
			MiniaturePose.arms(root,-0.46*t if weapon=="crossbow" else -0.25*t,-0.86*t)
			MiniaturePose.bend_arms(root,-0.66*t if weapon=="bow" else -0.48*t,-0.20*t)
		"guard":
			root.rotation.x=0.075*t
			MiniaturePose.arms(root,-0.40*t,-0.66*t)
			MiniaturePose.bend_arms(root,-0.40*t,-0.36*t)
			SecondaryMotion.arm_spread(root,0.16*t,-0.13*t)
			MiniaturePose.legs(root,[-0.08*t,0.14*t])
		"recoil":
			root.rotation.x=0.25*t
			root.rotation.z=-0.07*t
			MiniaturePose.arms(root,0.28*t,0.36*t)
			MiniaturePose.bend_arms(root,-0.30*t,-0.30*t)

	SecondaryMotion.action(root,kind,act,t)


static func _animate_beast(root: Node3D,wave: float,opposite: float) -> void:
	var head := root.get_node_or_null("Head") as Node3D
	var tail := root.get_node_or_null("Tail") as Node3D
	if head!=null:
		head.rotation.x=-0.07*opposite
	if tail!=null:
		tail.rotation.y=0.20*wave
		tail.rotation.x=0.05*opposite
