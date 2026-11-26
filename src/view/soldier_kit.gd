class_name SoldierKit
extends RefCounted
## Readable gear details from front, rear and tabletop camera.
const HIDE := Color("514034")
const METAL := Color("b3a07a")
const FUR := Color("9d9281")


static func decorate(root: Node3D,f: Figure,dye: Color,coat: Color) -> void:
	var id := f.def.id
	if id in ["ranger","tracker","thief","treasure_hunter","templar","vampire"]:
		ClothSculpt.cape(root,coat.darkened(0.16),0.90 if id in ["templar","vampire"] else 0.63,0.34)
	WizardLivery.decorate(root,"elementalist" if id in ["ranger","tracker","templar"] else "enchanter",dye,false)
	if f.ranged!=null:
		_quiver(root,f.ranged.id=="crossbow")
	match id:
		"thug":
			_strap(root,-1.0)
			MiniatureFactory.sphere(root,Vector3(0.25,1.11,0),Vector3(0.28,0.22,0.29),HIDE.lightened(0.15))
		"thief":
			for i in 3:
				var at := Vector3(0.13+i*0.055,0.81,-0.215)
				CreatureSculpt.limb(root,at,at-Vector3.UP*0.18,0.025,HIDE.darkened(0.25),0.65)
		"treasure_hunter":
			MiniatureFactory.sphere(root,Vector3(0,0.92,0.28),Vector3(0.43,0.48,0.26),HIDE)
			for i in 5:
				var angle := TAU*i/5.0
				MiniatureFactory.cylinder(root,Vector3(cos(angle)*0.12,0.68,0.41+sin(angle)*0.12),0.032,0.032,0.075,FUR)
		"barbarian":
			for i in 7:
				var x := (i-3)*0.07
				CreatureSculpt.limb(root,Vector3(x,0.70,-0.19),Vector3(x*1.3,0.46+0.04*(i%2),-0.24),0.052,FUR.darkened(0.1*(i%2)),0.22)
		"apothecary":
			for i in 3:
				var x := -0.19+i*0.18
				var potion := Color(["72ab81","b2874d","7597be"][i])
				MiniatureFactory.sphere(root,Vector3(x,0.73,-0.27),Vector3(0.115,0.17,0.10),potion)
				MiniatureFactory.cylinder(root,Vector3(x,0.82,-0.27),0.032,0.035,0.055,HIDE)
			MiniatureFactory.box(root,Vector3(0,0.91,0.26),Vector3(0.39,0.32,0.22),HIDE)
		"vampire":
			for side: float in [-1.0,1.0]:
				MiniatureFactory.box(root,Vector3(side*0.22,1.35,0.12),Vector3(0.12,0.26,0.16),dye)
				CreatureSculpt.limb(root,Vector3(side*0.042,1.24,-0.175),Vector3(side*0.042,1.19,-0.18),0.018,Color("ded9c3"),0.02)


static func _strap(root: Node3D,side: float) -> void:
	CreatureSculpt.limb(root,Vector3(side*0.20,1.13,-0.16),Vector3(-side*0.17,0.75,-0.23),0.035,HIDE,1.0)


static func _quiver(root: Node3D,bolts: bool) -> void:
	var a := Vector3(0.24,0.66,0.23)
	var b := Vector3(0.12,1.23 if bolts else 1.39,0.30)
	CreatureSculpt.limb(root,a,b,0.092,HIDE,1.0)
	CreatureSculpt.limb(root,b-Vector3.UP*0.045,b,0.105,METAL,1.0)
	for i in 4:
		var off := Vector3((i-1.5)*0.035,0,0.016*(i%2))
		var top := b+off+Vector3.UP*(0.14+0.035*(i%2))
		CreatureSculpt.limb(root,b+off,top,0.012,HIDE.lightened(0.32),1.0)
		MiniatureFactory.box(root,top-Vector3.UP*0.035,Vector3(0.055,0.075,0.025),FUR)
