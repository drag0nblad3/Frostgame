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


static func create(root: Node3D,f: Figure,school: String,faction: Color) -> void:
	var index := identity(f)
	var apprentice := f.def.role=="apprentice"
	var coat := cloth(f)
	var lining := Color(COATS[posmod(index*3+1,COATS.size())]).lightened(0.12)
	var skin := Color(SKINS[posmod(index*5,SKINS.size())])
	var hair := Color(HAIR[posmod(index*7,HAIR.size())])
	var trim := SchoolArt.accent(school)
	var accent := SchoolArt.glow(school)
	var long_robe := school in ["chronomancer","necromancer","sigilist","soothsayer","thaumaturge"] and not apprentice
	var livery := WizardLivery.color(faction)
	var profile := posmod(index,4)
	for x: float in [-0.13,0.13]:
		var leg := MiniaturePose.leg(root,1 if x>0 else 0,Vector3(x,0.60,0))
		var first := root.get_child_count()
		CreatureSculpt.limb(root,Vector3(x,0.60,0),Vector3(x*1.2,0.19,0.035),0.105,coat.darkened(0.20),0.9)
		MiniatureFactory.sphere(root,Vector3(x*1.2,0.12,-0.06),Vector3(0.21,0.21,0.34),LEATHER)
		MiniatureFactory.cylinder(root,Vector3(x*1.2,0.26,0.02),0.11,0.10,0.18,LEATHER)
		MiniaturePose.attach(root,leg,first)
	if long_robe:
		WizardTailoring.skirt(root,coat,lining,0.15,0.36,profile,false)
	else:
		WizardTailoring.skirt(root,coat,lining,0.32 if apprentice else 0.23,0.29 if apprentice else 0.34,profile,true)
	WizardTailoring.torso(root,coat,lining,profile,apprentice)
	MiniatureFactory.box(root,Vector3(0,0.74,-0.20),Vector3(0.49,0.085,0.095),LEATHER)
	WeaponSculpt.metal(MiniatureFactory.box(root,Vector3(0,0.74,-0.255),Vector3(0.105,0.10,0.04),trim))
	for x: float in [-0.30,0.30]:
		var pivot := MiniaturePose.arm(root,x>0)
		var first := root.get_child_count()
		CreatureSculpt.limb(root,Vector3(x*0.86,1.12,0),Vector3(x*1.14,0.94,0.015),0.125,coat,0.8)
		CreatureSculpt.limb(root,Vector3(x*1.14,0.94,0.015),Vector3(x*1.20,0.77,-0.09),0.10,lining,0.95)
		CreatureSculpt.limb(root,Vector3(x*1.18,0.86,-0.05),Vector3(x*1.20,0.78,-0.08),0.109,livery,0.96)
		CreatureSculpt.limb(root,Vector3(x*1.20,0.79,-0.08),Vector3(x*1.20,0.76,-0.09),0.106,trim,1.0)
		MiniatureFactory.sphere(root,Vector3(x*1.20,0.75,-0.09),Vector3(0.13,0.16,0.14),skin)
		MiniatureFactory.sphere(root,Vector3(x*1.04,0.76,-0.15),Vector3(0.065,0.085,0.07),skin)
		MiniaturePose.attach(root,pivot,first)
	_face(root,skin,hair,index,apprentice)
	WizardWardrobe.dress(root,school,coat,lining,hair,apprentice)
	WizardLivery.decorate(root,school,livery,apprentice)
	SchoolArt.dress(root,school,apprentice)
	WizardTailoring.satchel(root,profile,LEATHER)
	CreatureSculpt.eye(root,Vector3(0,1.04,-0.25),accent)


static func _face(root: Node3D,skin: Color,hair: Color,index: int,apprentice: bool) -> void:
	WizardHead.sculpt(root,skin,hair,index,apprentice)
