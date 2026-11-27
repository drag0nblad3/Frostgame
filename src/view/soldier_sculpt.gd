class_name SoldierSculpt
extends RefCounted
## Winter mercenaries: layered practical clothing and role-specific equipment.
const STEEL := Color("849098")
const LEATHER := Color("514034")
const FUR := Color("9c9281")
const BRASS := Color("b49a64")


static func create(root: Node3D,f: Figure,faction: Color) -> void:
	var id := f.def.id
	var index := WizardSculpt.identity(f)
	var coat := WizardSculpt.cloth(f)
	var skin := Color(WizardSculpt.SKINS[posmod(index*5,WizardSculpt.SKINS.size())])
	var hair := Color(WizardSculpt.HAIR[posmod(index*7,WizardSculpt.HAIR.size())])
	var dye := WizardLivery.color(faction)
	var plate := id in ["knight","templar","man_at_arms","marksman"]
	var mail := id in ["infantryman","crossbowman","archer","ranger"]
	var heavy := id in ["knight","templar","barbarian","man_at_arms"]
	if id=="vampire":
		skin=Color("bcb5ab")
		hair=Color("26242b")
		coat=Color("373039")
		dye=Color("742d43")
	var sleeve := coat.darkened(0.12)
	var chest := coat if not plate else STEEL.darkened(0.24)
	WizardTailoring.skirt(root,coat,LEATHER,0.33 if heavy else 0.43,0.30,posmod(index,4),true)
	for side: float in [-1.0,1.0]:
		var hip := Vector3(side*0.13,0.62,0)
		var knee := Vector3(side*0.16,0.37,-0.045 if side>0 else 0.04)
		var foot := Vector3(side*0.17,0.11,-0.09 if side>0 else 0.04)
		var leg := MiniaturePose.leg(root,1 if side>0 else 0,hip)
		var leg_first := root.get_child_count()
		CreatureSculpt.limb(root,hip,knee,0.115,coat.darkened(0.18),0.92)
		MiniaturePose.attach(root,leg,leg_first)
		var shin := MiniaturePose.joint(root,leg,"Knee",knee)
		leg_first=root.get_child_count()
		CreatureSculpt.limb(root,knee,foot,0.102,LEATHER,0.88)
		MiniatureFactory.sphere(root,foot+Vector3(0,-0.015,-0.06),Vector3(0.22,0.19,0.34),LEATHER.darkened(0.12))
		CreatureSculpt.limb(root,knee,knee-Vector3.UP*0.07,0.12,LEATHER.lightened(0.13),1.0)
		if plate:
			WeaponSculpt.metal(MiniatureFactory.sphere(root,knee+Vector3(0,0,-0.075),Vector3(0.18,0.19,0.12),STEEL))
			WeaponSculpt.metal(MiniatureFactory.box(root,foot+Vector3(0,0.14,-0.085),Vector3(0.17,0.21,0.065),STEEL.darkened(0.1)))
		TabletopKit.boot(root,foot+Vector3(0,-0.015,-0.06),LEATHER,plate)
		MiniaturePose.attach(root,shin,leg_first)
		var pivot := MiniaturePose.arm(root,side>0)
		var first := root.get_child_count()
		var shoulder := Vector3(side*0.26,1.12,0)
		var elbow := Vector3(side*0.34,0.95,0.015)
		var hand := Vector3(side*0.37,0.75,-0.09)
		CreatureSculpt.limb(root,shoulder,elbow,0.13 if heavy else 0.11,sleeve,0.80)
		if plate:
			_pauldron(root,shoulder,side,id=="knight")
		elif id=="barbarian":
			MiniatureFactory.sphere(root,shoulder,Vector3(0.29,0.28,0.33),FUR)
		MiniaturePose.attach(root,pivot,first)
		var forearm := MiniaturePose.joint(root,pivot,"Elbow",elbow)
		first=root.get_child_count()
		CreatureSculpt.limb(root,elbow,hand,0.095,LEATHER if heavy else sleeve,0.85)
		CreatureSculpt.limb(root,elbow.lerp(hand,0.72),elbow.lerp(hand,0.92),0.104,dye,0.94)
		MiniatureFactory.sphere(root,hand,Vector3(0.15,0.17,0.15),LEATHER if plate else skin)
		if plate:
			WeaponSculpt.metal(MiniatureFactory.sphere(root,elbow+Vector3(0,0,-0.04),Vector3(0.19,0.18,0.16),STEEL))
		TabletopKit.cuff(root,hand+Vector3(0,0.05,0),STEEL if plate else dye,plate)
		MiniaturePose.attach(root,forearm,first)
	WizardTailoring.torso(root,chest,coat.lightened(0.13),2 if heavy else 0,false)
	if plate or mail:
		SoldierArmor.body(root,plate,heavy,dye)
	MiniatureFactory.box(root,Vector3(0,0.74,-0.20),Vector3(0.49,0.085,0.095),LEATHER)
	WeaponSculpt.metal(MiniatureFactory.box(root,Vector3(0,0.74,-0.255),Vector3(0.105,0.10,0.04),BRASS))
	var head := MiniaturePose.joint(root,root,"Head",Vector3(0,1.20,0))
	var head_first := root.get_child_count()
	WizardHead.sculpt(root,skin,hair,index,false)
	SoldierArmor.head(root,id,coat,dye)
	MiniaturePose.attach(root,head,head_first)
	SoldierKit.decorate(root,f,dye,coat)
	WizardTailoring.satchel(root,posmod(index,4),LEATHER)


static func _pauldron(root: Node3D,p: Vector3,side: float,ornate: bool) -> void:
	for i in 3:
		var at := p+Vector3(side*i*0.045,-i*0.045,0)
		WeaponSculpt.metal(MiniatureFactory.sphere(root,at,Vector3(0.30-i*0.035,0.16,0.31),STEEL.darkened(i*0.065)))
	if ornate:
		WeaponSculpt.metal(MiniatureFactory.sphere(root,p+Vector3(0,0.075,-0.05),Vector3(0.12,0.09,0.13),BRASS))
