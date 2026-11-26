class_name WizardWardrobe
extends RefCounted
## School silhouettes use distinct tailoring and headwear, not school-colored fabric.
const LEATHER := Color("49392c")
const FUR := Color("99917d")
const BONE := Color("c5b89e")


static func dress(root: Node3D,school: String,coat: Color,lining: Color,hair: Color,apprentice: bool) -> void:
	var cap := coat.darkened(0.22)
	var short := 0.54 if apprentice else 0.83
	match school:
		"chronomancer":
			ClothSculpt.cape(root,lining,short,0.28)
			MiniatureFactory.cylinder(root,Vector3(0,1.46 if apprentice else 1.48,0),0.19 if apprentice else 0.17,0.20,0.09 if apprentice else 0.14,cap)
			MiniatureFactory.cylinder(root,Vector3(0,1.43,0),0.21,0.21,0.045,LEATHER)
			_collar(root,lining,0.19)
		"elementalist":
			_mantle(root,FUR,0.26 if apprentice else 0.32)
			ClothSculpt.cape(root,lining,short,0.43)
			for side: float in [-1.0,1.0]:
				MiniatureFactory.sphere(root,Vector3(side*0.15,1.41,0.03),Vector3(0.16,0.16,0.22),hair)
			# A bare head and swept hair rather than a hat.
		"enchanter":
			var apron := MiniatureFactory.box(root,Vector3(0,0.61,-0.215),Vector3(0.39,0.53,0.075),LEATHER)
			apron.rotation.x=-0.08
			for side: float in [-1.0,1.0]:
				CreatureSculpt.limb(root,Vector3(side*0.16,1.13,-0.13),Vector3(side*0.13,0.82,-0.22),0.038,LEATHER,1.0)
				WeaponSculpt.metal(MiniatureFactory.sphere(root,Vector3(side*0.16,0.88,-0.25),Vector3.ONE*0.055,Color("b69d6e")))
			MiniatureFactory.sphere(root,Vector3(0,1.46,0),Vector3(0.37,0.18,0.33),cap)
			MiniatureFactory.box(root,Vector3(0,1.40,-0.16),Vector3(0.29,0.055,0.08),LEATHER)
		"illusionist":
			ClothSculpt.cape(root,lining,short,0.40)
			_collar(root,lining,0.25)
			var brim := MiniatureFactory.cylinder(root,Vector3(0,1.47,0),0.30,0.30,0.045,cap)
			brim.rotation.z=-0.16
			var crown := MiniatureFactory.cylinder(root,Vector3(0,1.54,0),0.18,0.22,0.18,cap)
			crown.rotation.z=-0.16
			if not apprentice:
				CreatureSculpt.limb(root,Vector3(-0.23,1.49,0.05),Vector3(-0.37,1.78,0.09),0.05,BONE,0.10)
			else:
				MiniatureFactory.cylinder(root,Vector3(0,1.48,0),0.22,0.23,0.042,lining)
		"necromancer":
			ClothSculpt.hood(root,cap)
			ClothSculpt.cape(root,lining,short,0.36)
			_mantle(root,coat.darkened(0.30),0.31)
			for side: float in [-1.0,1.0]:
				for i in (1 if apprentice else 3):
					var at := Vector3(side*(0.13+i*0.075),1.14-i*0.035,-0.12)
					CreatureSculpt.limb(root,at,at+Vector3(side*0.04,-0.12,-0.025),0.035,BONE,0.65)
		"sigilist":
			ClothSculpt.cape(root,lining,short,0.27)
			MiniatureFactory.cylinder(root,Vector3(0,1.51,0),0.18,0.20,0.16,cap)
			if not apprentice:
				MiniatureFactory.box(root,Vector3(0,1.59,0),Vector3(0.47,0.055,0.39),cap)
			else:
				MiniatureFactory.sphere(root,Vector3(0,1.53,0),Vector3(0.37,0.17,0.34),cap)
			CreatureSculpt.limb(root,Vector3(0.19,1.60,0),Vector3(0.20,1.45,-0.02),0.018,BONE,0.8)
			for side: float in [-1.0,1.0]:
				MiniatureFactory.box(root,Vector3(side*0.17,0.97,-0.20),Vector3(0.10,0.28,0.055),lining)
		"soothsayer":
			ClothSculpt.cape(root,lining,short,0.31)
			MiniatureFactory.sphere(root,Vector3(0,1.45,0.025),Vector3(0.43,0.23,0.40),lining)
			for y: float in [1.43,1.50]:
				var wrap := MiniatureFactory.cylinder(root,Vector3(0,y,0.02),0.203,0.213,0.055,cap)
				wrap.rotation.z=0.13
			if not apprentice:
				MiniatureFactory.box(root,Vector3(0,1.34,-0.16),Vector3(0.30,0.075,0.06),lining)
		"summoner":
			ClothSculpt.cape(root,lining,short,0.40)
			_collar(root,cap,0.24)
			MiniatureFactory.cylinder(root,Vector3(0,1.45,0),0.19,0.20,0.07,LEATHER)
			for side: float in [-1.0,1.0]:
				var a := Vector3(side*0.15,1.46,0)
				var b := a+Vector3(side*0.11,0.09 if apprentice else 0.15,0.03)
				CreatureSculpt.limb(root,a,b,0.065,BONE,0.65)
				if not apprentice:
					CreatureSculpt.limb(root,b,b+Vector3(side*0.03,0.10,-0.08),0.04,BONE,0.03)
		"thaumaturge":
			_mantle(root,lining,0.37)
			ClothSculpt.cape(root,coat,short,0.37)
			var mitre := MiniatureFactory.cylinder(root,Vector3(0,1.57,0),0.015,0.22,0.36 if not apprentice else 0.25,lining)
			mitre.scale.z=0.66
			MiniatureFactory.box(root,Vector3(0,1.54,-0.15),Vector3(0.045,0.19,0.035),BONE)
		"witch":
			ClothSculpt.cape(root,lining,short,0.39)
			_mantle(root,FUR.darkened(0.15),0.29)
			var brim := MiniatureFactory.cylinder(root,Vector3(0,1.46,0),0.26 if apprentice else 0.34,0.29 if apprentice else 0.38,0.06,cap)
			brim.rotation.z=0.08
			var a := Vector3(0,1.48,0)
			var b := Vector3(-0.055,1.70,0.035)
			CreatureSculpt.limb(root,a,b,0.21,cap,0.42)
			CreatureSculpt.limb(root,b,b+Vector3(-0.14,0.07,0.025),0.088,cap,0.01)
		_:
			ClothSculpt.hood(root,cap)
			ClothSculpt.cape(root,lining,short)


static func _mantle(root: Node3D,color: Color,width: float) -> void:
	for i in 7:
		var angle := PI*float(i)/6.0
		var at := Vector3(cos(angle)*width,1.12,sin(angle)*0.17)
		MiniatureFactory.sphere(root,at,Vector3(0.22,0.20,0.26),color.lightened(0.04*float(i%2)))
		for side: float in [-1.0,1.0]:
			var tuft := at+Vector3(side*0.048,0.015,-0.075)
			CreatureSculpt.limb(root,tuft,tuft+Vector3(side*0.035,-0.095,-0.04),0.035,color.darkened(0.09),0.09)


static func _collar(root: Node3D,color: Color,height: float) -> void:
	for side: float in [-1.0,1.0]:
		var panel := MiniatureFactory.box(root,Vector3(side*0.19,1.20+height*0.20,0.13),Vector3(0.10,height,0.23),color)
		panel.rotation.z=-side*0.25
	MiniatureFactory.box(root,Vector3(0,1.21+height*0.2,0.19),Vector3(0.36,height,0.06),color)
