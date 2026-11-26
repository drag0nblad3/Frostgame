class_name WizardSculpt
extends RefCounted
## Individual winter adventurers. Cloth and complexion depend on identity, not school.
## Equipment and head/garment geometry distinguish disciplines at tabletop scale.

const COATS := ["574a3d","4b5556","766953","343b43","6a5d60","585f48","777b76","554b45"]
const SKINS := ["bd9270","e2b491","80523e","9c7155","cf9c83","664738"]
const HAIR := ["332b28","574332","c1b6a2","8c543b","282d30","77726c"]
const LEATHER := Color("49372c")
const BONE := Color("c6b99b")


static func identity(f: Figure) -> int:
	# Persist across campaign deployments and reloads; never use battle RNG.
	return (f.campaign_id if f.campaign_id>=0 else f.id)+17*maxi(0,f.original_side)


static func cloth(f: Figure) -> Color:
	return Color(COATS[posmod(identity(f)*5+3,COATS.size())])


static func create(root: Node3D,f: Figure,school: String) -> void:
	var index := identity(f)
	var apprentice := f.def.role=="apprentice"
	var coat := cloth(f)
	var lining := Color(COATS[posmod(index*3+1,COATS.size())]).lightened(0.12)
	var skin := Color(SKINS[posmod(index*5,SKINS.size())])
	var hair := Color(HAIR[posmod(index*7,HAIR.size())])
	var trim := SchoolArt.accent(school)
	var accent := SchoolArt.glow(school)
	var long_robe := school in ["chronomancer","necromancer","sigilist","soothsayer","thaumaturge"] and not apprentice
	for x: float in [-0.13,0.13]:
		CreatureSculpt.limb(root,Vector3(x,0.60,0),Vector3(x*1.2,0.19,0.035),0.105,coat.darkened(0.20),0.9)
		MiniatureFactory.sphere(root,Vector3(x*1.2,0.12,-0.06),Vector3(0.21,0.21,0.34),LEATHER)
		MiniatureFactory.cylinder(root,Vector3(x*1.2,0.26,0.02),0.11,0.10,0.18,LEATHER)
	if long_robe:
		ClothSculpt.robe(root,coat)
	else:
		var skirt := MiniatureFactory.cylinder(root,Vector3(0,0.60,0),0.22,0.32 if not apprentice else 0.27,0.56,coat)
		skirt.scale.z=0.78
		# Split coat fronts leave boots visible.
		for side: float in [-1.0,1.0]:
			var flap := MiniatureFactory.box(root,Vector3(side*0.115,0.49,-0.20),Vector3(0.17,0.37,0.055),lining)
			flap.rotation.z=side*0.08
	MiniatureFactory.sphere(root,Vector3(0,0.96,0),Vector3(0.52,0.53,0.38),coat)
	MiniatureFactory.box(root,Vector3(0,0.74,-0.20),Vector3(0.49,0.085,0.095),LEATHER)
	WeaponSculpt.metal(MiniatureFactory.box(root,Vector3(0,0.74,-0.255),Vector3(0.105,0.10,0.04),trim))
	for x: float in [-0.30,0.30]:
		var pivot := MiniaturePose.arm(root,x>0)
		var first := root.get_child_count()
		CreatureSculpt.limb(root,Vector3(x*0.86,1.12,0),Vector3(x*1.14,0.94,0.015),0.125,coat,0.8)
		CreatureSculpt.limb(root,Vector3(x*1.14,0.94,0.015),Vector3(x*1.20,0.77,-0.09),0.10,lining,0.95)
		CreatureSculpt.limb(root,Vector3(x*1.19,0.81,-0.07),Vector3(x*1.20,0.76,-0.09),0.105,trim,1.0)
		MiniatureFactory.sphere(root,Vector3(x*1.20,0.75,-0.09),Vector3.ONE*0.15,skin)
		MiniaturePose.attach(root,pivot,first)
	_face(root,skin,hair,index,apprentice)
	WizardWardrobe.dress(root,school,coat,lining,hair,apprentice)
	SchoolArt.dress(root,school,apprentice)
	MiniatureFactory.box(root,Vector3(-0.22,0.68,-0.15),Vector3(0.16,0.21,0.12),LEATHER)
	MiniatureFactory.box(root,Vector3(-0.22,0.73,-0.22),Vector3(0.17,0.09,0.035),LEATHER.lightened(0.18))
	CreatureSculpt.eye(root,Vector3(0,1.04,-0.25),accent)


static func _face(root: Node3D,skin: Color,hair: Color,index: int,apprentice: bool) -> void:
	MiniatureFactory.sphere(root,Vector3(0,1.30,-0.015),Vector3(0.32,0.38,0.31),skin)
	MiniatureFactory.sphere(root,Vector3(0,1.40,0.035),Vector3(0.34,0.25,0.32),hair)
	for x: float in [-0.155,0.155]:
		MiniatureFactory.sphere(root,Vector3(x,1.30,0),Vector3(0.07,0.11,0.075),skin)
		MiniatureFactory.sphere(root,Vector3(x*0.46,1.33,-0.155),Vector3(0.045,0.04,0.03),Color("282522"))
		MiniatureFactory.box(root,Vector3(x*0.46,1.365,-0.158),Vector3(0.065,0.019,0.025),hair)
	MiniatureFactory.sphere(root,Vector3(0,1.28,-0.177),Vector3(0.065,0.083,0.09),skin.lightened(0.10))
	MiniatureFactory.box(root,Vector3(0,1.22,-0.15),Vector3(0.09,0.018,0.025),skin.darkened(0.22))
	if not apprentice and posmod(index,3)!=1:
		var length := 0.28 if posmod(index,3)==0 else 0.17
		MiniatureFactory.sphere(root,Vector3(0,1.18-length*0.20,-0.15),Vector3(0.23,length,0.17),hair)
	elif posmod(index,3)==1:
		for side: float in [-1.0,1.0]:
			CreatureSculpt.limb(root,Vector3(side*0.14,1.40,0.05),Vector3(side*0.19,1.14,0.07),0.065,hair,0.65)
