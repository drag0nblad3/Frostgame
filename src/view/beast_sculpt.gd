class_name BeastSculpt
extends RefCounted
## Species-specific quadruped shapes, with bent limbs and individual head geometry.
const DARK := Color("303135")
const IVORY := Color("cfc5a7")


static func create(root: Node3D,f: Figure,faction: Color) -> void:
	var id := f.def.id
	var bear := id=="bear"
	var boar := id=="boar"
	var cat := id=="snow_leopard"
	var rat := id=="giant_rat"
	var dog := id in ["war_hound","wild_dog"]
	var fur := Color("777b7b") if id=="wolf" else (Color("c6c8c1") if cat else Color("665044"))
	if rat:
		fur=Color("676268")
	elif dog:
		fur=Color("987759") if id=="war_hound" else Color("796b5b")
	var bulk := 1.28 if bear else (1.10 if boar else (0.73 if rat else 1.0))
	var height := 0.54 if bear else (0.44 if boar or rat else 0.56)
	var width := 0.33 if bear or boar else (0.24 if cat else 0.22)
	var long := 0.52 if bear or cat else 0.45
	var shoulder := Vector3(0,height,-0.23)
	var rump := Vector3(0,height-0.045,0.32)
	MiniatureFactory.sphere(root,Vector3(0,height,0.05),Vector3(width*1.85,0.51,long*1.95)*bulk,fur)
	MiniatureFactory.sphere(root,shoulder*bulk,Vector3(width*2.0,0.57 if bear else 0.44,0.44)*bulk,fur.lightened(0.07))
	MiniatureFactory.sphere(root,rump*bulk,Vector3(width*1.7,0.44,0.46)*bulk,fur.darkened(0.05))
	for side: float in [-1.0,1.0]:
		for rear in [false,true]:
			var z := 0.32 if rear else -0.25
			var hip := Vector3(side*width*0.73,height-0.07,z)*bulk
			var knee := Vector3(side*width*0.9,0.25,z+(0.11 if rear else -0.055))*bulk
			var foot := Vector3(side*width*1.0,0.07,z+(-0.045 if rear else -0.095))*bulk
			var index := (2 if side>0 else 0)+(1 if rear else 0)
			var pivot := MiniaturePose.leg(root,index,hip)
			var first := root.get_child_count()
			CreatureSculpt.limb(root,hip,knee,(0.15 if bear else 0.10)*bulk,fur,0.73)
			MiniaturePose.attach(root,pivot,first)
			var shin := MiniaturePose.joint(root,pivot,"Knee",knee)
			first=root.get_child_count()
			CreatureSculpt.limb(root,knee,foot,(0.11 if bear else 0.067)*bulk,fur.darkened(0.16),0.84)
			MiniatureFactory.sphere(root,foot+Vector3(0,0,-0.04)*bulk,Vector3(0.24 if bear else 0.15,0.13,0.23)*bulk,DARK if boar else fur.darkened(0.22))
			if not boar:
				for i in 3:
					CreatureSculpt.limb(root,foot+Vector3((i-1)*0.04,0,-0.12)*bulk,foot+Vector3((i-1)*0.04,-0.01,-0.16)*bulk,0.013*bulk,IVORY,0.02)
			MiniaturePose.attach(root,shin,first)
	var head := Vector3(0,height+(0.10 if bear or dog else 0.045),-0.49)*bulk
	var neck := MiniaturePose.joint(root,root,"Head",head+Vector3(0,0,0.12)*bulk)
	var head_first := root.get_child_count()
	var head_size := Vector3(0.46,0.39,0.43) if bear else (Vector3(0.35,0.32,0.34) if cat else Vector3(0.30,0.30,0.36))
	MiniatureFactory.sphere(root,head,head_size*bulk,fur)
	var snout := Vector3(0,-0.055,-0.21 if cat or bear else -0.29)*bulk
	var muzzle := Vector3(0.27,0.18,0.22) if cat or bear else Vector3(0.20,0.20,0.37)
	MiniatureFactory.sphere(root,head+snout,muzzle*bulk,fur.lightened(0.12) if cat or bear else fur.darkened(0.18))
	MiniatureFactory.sphere(root,head+snout+Vector3(0,0.025,-muzzle.z*0.44)*bulk,Vector3(0.15,0.09,0.065)*bulk,Color("ae7b77") if rat else DARK)
	for side: float in [-1.0,1.0]:
		var ear := head+Vector3(side*0.13,0.13,0.06)*bulk
		if bear or cat or rat:
			MiniatureFactory.sphere(root,ear,Vector3(0.15,0.16,0.10)*bulk,fur.darkened(0.12))
			MiniatureFactory.sphere(root,ear+Vector3(0,0,-0.045)*bulk,Vector3(0.09,0.09,0.04)*bulk,Color("a88e81") if rat else fur.darkened(0.30))
		else:
			CreatureSculpt.limb(root,ear,ear+Vector3(side*0.04,0.20 if not dog else 0.11,0.01)*bulk,0.085*bulk,fur,0.08)
		var eye := head+Vector3(side*0.12,0.045,-0.13)*bulk
		MiniatureFactory.sphere(root,eye,Vector3.ONE*0.075*bulk,DARK)
		MiniatureFactory.sphere(root,eye+Vector3(0,0,-0.032)*bulk,Vector3.ONE*0.037*bulk,Color("d3b67b"))
		if boar:
			var tusk := head+snout+Vector3(side*0.11,-0.04,0)*bulk
			CreatureSculpt.limb(root,tusk,tusk+Vector3(side*0.07,0.13,-0.025)*bulk,0.05*bulk,IVORY,0.03)
	MiniaturePose.attach(root,neck,head_first)
	for side: float in [-1.0,1.0]:
		if cat:
			for i in 7:
				var spot := Vector3(side*width*0.91,height+sin(i*2.0)*0.13,-0.31+i*0.115)*bulk
				MiniatureFactory.sphere(root,spot,Vector3(0.042,0.09,0.083)*bulk,Color("5c5c60"))
	if boar or id=="wolf":
		for i in 7:
			var at := Vector3(0,height+0.20,-0.35+i*0.10)*bulk
			CreatureSculpt.limb(root,at,at+Vector3(0,0.10,0.06)*bulk,0.062*bulk,fur.darkened(0.20),0.06)
	var tail := Vector3(0,height-0.03,0.46)*bulk
	var tail_pivot := MiniaturePose.joint(root,root,"Tail",tail)
	var tail_first := root.get_child_count()
	var middle := tail+Vector3(0.07,0.07,0.23 if cat or rat or dog else 0.12)*bulk
	var tip := middle+Vector3(0.15,0.07,0.27 if cat or rat else 0.08)*bulk
	CreatureSculpt.limb(root,tail,middle,0.092*bulk if cat else 0.055*bulk,Color("9d8282") if rat else fur,0.72)
	CreatureSculpt.limb(root,middle,tip,0.066*bulk if cat else 0.038*bulk,Color("9d8282") if rat else fur.darkened(0.12),0.25)
	MiniaturePose.attach(root,tail_pivot,tail_first)
	if id=="war_hound":
		var collar := MiniatureFactory.cylinder(root,Vector3(0,height,-0.33)*bulk,0.18,0.19,0.09,WizardLivery.color(faction))
		collar.rotation.x=PI*0.5
		collar.scale=Vector3.ONE*bulk
		WeaponSculpt.metal(MiniatureFactory.sphere(root,Vector3(0,height-0.15,-0.38)*bulk,Vector3.ONE*0.095,IVORY))
