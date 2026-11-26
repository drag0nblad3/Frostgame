class_name BruteSculpt
extends RefCounted
## Four distinct anatomical profiles with independently animated arms.
const IVORY := Color("cfc6ae")
const DARK := Color("333b40")
const HIDE := Color("5f5143")


static func create(root: Node3D,f: Figure) -> void:
	var id := f.def.id
	var gorilla := id=="white_gorilla"
	var wolf := id=="werewolf"
	var troll := id=="snow_troll"
	var giant := id=="frost_giant"
	var skin := Color("b6c1c2") if gorilla else (Color("767c7b") if wolf else (Color("869ca2") if troll else Color("a7b7bd")))
	var width := 0.36 if gorilla or troll else 0.27
	var head_y := 1.27 if gorilla else (1.34 if troll else 1.45)
	var shoulder_y := 1.10 if gorilla else 1.17
	MiniatureFactory.sphere(root,Vector3(0,0.92,0),Vector3(width*2.0,0.70,0.51),skin)
	MiniatureFactory.sphere(root,Vector3(0,0.60,0.04),Vector3(0.47,0.35,0.38),skin.darkened(0.12))
	for side: float in [-1.0,1.0]:
		var knee := Vector3(side*0.22,0.32,-0.10 if wolf else 0.04)
		var foot := Vector3(side*0.23,0.10,-0.07)
		CreatureSculpt.limb(root,Vector3(side*0.16,0.62,0),knee,0.16 if gorilla or troll else 0.13,skin,0.73)
		CreatureSculpt.limb(root,knee,foot,0.105,skin.darkened(0.15),0.8)
		MiniatureFactory.sphere(root,foot,Vector3(0.25,0.17,0.35),DARK if giant else skin.darkened(0.26))
		var pivot := MiniaturePose.arm(root,side>0)
		var first := root.get_child_count()
		var a := Vector3(side*width,shoulder_y,0)
		var b := Vector3(side*(width+0.13),0.74,-0.08)
		var c := Vector3(side*(width+0.15),0.27 if gorilla else (0.42 if troll else 0.65),-0.23)
		MiniatureFactory.sphere(root,a,Vector3(0.34,0.36,0.36),skin)
		CreatureSculpt.limb(root,a,b,0.19 if gorilla else 0.15,skin,0.74)
		CreatureSculpt.limb(root,b,c,0.16 if gorilla or troll else 0.11,skin.darkened(0.09),0.78)
		MiniatureFactory.sphere(root,c,Vector3(0.26,0.22,0.24),skin.darkened(0.17))
		for i in 3:
			CreatureSculpt.limb(root,c+Vector3((i-1)*0.07,-0.02,-0.08),c+Vector3((i-1)*0.07,-0.09,-0.15),0.035,IVORY if wolf or troll else skin.darkened(0.24),0.15)
		if giant and side>0:
			var top := c+Vector3(0.12,0.91,0.015)
			CreatureSculpt.limb(root,c-Vector3.UP*0.20,top,0.055,HIDE,0.95)
			WeaponSculpt.metal(MiniatureFactory.box(root,top,Vector3(0.43,0.29,0.27),Color("819ba7")))
			WeaponSculpt.metal(MiniatureFactory.box(root,top+Vector3(0.18,0,0),Vector3(0.08,0.32,0.29),DARK))
		MiniaturePose.attach(root,pivot,first)
		MiniatureFactory.sphere(root,Vector3(side*0.15,1.03,-0.19),Vector3(0.29,0.30,0.15),skin.lightened(0.08))
		if gorilla or wolf or troll:
			for i in 4:
				var at := Vector3(side*(width-0.06),1.18-i*0.10,0.10)
				CreatureSculpt.limb(root,at,at+Vector3(side*0.15,-0.12,0.045),0.060,skin.lightened(0.08),0.05)
	_head(root,id,skin,head_y)
	if giant:
		WizardTailoring.skirt(root,HIDE,Color("b1a597"),0.36,0.33,2,true)
		MiniatureFactory.box(root,Vector3(0,0.74,-0.22),Vector3(0.46,0.13,0.07),HIDE)
		WeaponSculpt.metal(MiniatureFactory.sphere(root,Vector3(0,0.75,-0.275),Vector3(0.14,0.14,0.06),Color("9f9a83")))
		ClothSculpt.cape(root,Color("52646c"),0.82,0.40)
	elif troll:
		for i in 6:
			var at := Vector3(0,0.75+i*0.11,0.25)
			CreatureSculpt.limb(root,at,at+Vector3(0,0.13,0.15),0.075,Color("9db6bd"),0.03)
	root.scale=Vector3.ONE*(1.4 if f.def.traits.has("large") else 1.0)


static func _head(root: Node3D,id: String,skin: Color,y: float) -> void:
	var p := Vector3(0,y,-0.12)
	MiniatureFactory.sphere(root,p,Vector3(0.40,0.38,0.36),skin.darkened(0.1))
	var wolf := id=="werewolf"
	var gorilla := id=="white_gorilla"
	var troll := id=="snow_troll"
	MiniatureFactory.sphere(root,p+Vector3(0,-0.07,-0.20),Vector3(0.28,0.17,0.36 if wolf else 0.20),DARK if gorilla else skin.darkened(0.20))
	for side: float in [-1.0,1.0]:
		CreatureSculpt.eye(root,p+Vector3(side*0.10,0.04,-0.18),Color("b5d8dd"))
		MiniatureFactory.sphere(root,p+Vector3(side*0.10,0.085,-0.16),Vector3(0.14,0.07,0.11),skin.darkened(0.18))
		if wolf:
			CreatureSculpt.limb(root,p+Vector3(side*0.14,0.12,0),p+Vector3(side*0.20,0.34,0.02),0.083,skin,0.04)
		elif gorilla:
			MiniatureFactory.sphere(root,p+Vector3(side*0.20,0.02,0),Vector3(0.09,0.14,0.09),DARK)
		if wolf or troll:
			CreatureSculpt.limb(root,p+Vector3(side*0.11,-0.08,-0.24),p+Vector3(side*0.11,-0.16,-0.27),0.031,IVORY,0.04)
	if id=="frost_giant":
		for i in 5:
			var x := (i-2)*0.042
			CreatureSculpt.limb(root,p+Vector3(x,-0.10,-0.17),p+Vector3(x*0.6,-0.32,-0.16),0.048,IVORY,0.18)
