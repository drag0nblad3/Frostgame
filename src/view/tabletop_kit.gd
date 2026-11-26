class_name TabletopKit
extends RefCounted
## Deliberately chunky trim and accessories visible at normal battlefield zoom.
const BRASS := Color("b6a16d")
const STEEL := Color("a2adb1")
const LEATHER := Color("504039")


static func boot(root: Node3D,foot: Vector3,hide: Color,armored: bool) -> void:
	var sole := MiniatureFactory.sphere(root,foot+Vector3(0,-0.055,-0.005),Vector3(0.22,0.07,0.33),hide.darkened(0.25))
	sole.rotation.x=0.03
	if armored:
		for i in 2:
			WeaponSculpt.metal(MiniatureFactory.box(root,foot+Vector3(0,0.037,-0.095+i*0.058),Vector3(0.175,0.046,0.065),STEEL.darkened(i*0.15)))
	else:
		for i in 2:
			MiniatureFactory.box(root,foot+Vector3(0,0.045,-0.055+i*0.058),Vector3(0.16,0.026,0.036),hide.lightened(0.21))


static func cuff(root: Node3D,at: Vector3,trim: Color,armored: bool) -> void:
	var band := MiniatureFactory.cylinder(root,at,0.103,0.113,0.043,trim.lightened(0.15))
	band.rotation.x=0.38
	if armored:
		WeaponSculpt.metal(band)
	var stud := MiniatureFactory.sphere(root,at+Vector3(0,0,-0.10),Vector3.ONE*0.048,BRASS)
	WeaponSculpt.metal(stud)


static func pouch(root: Node3D,at: Vector3,size: Vector3) -> void:
	MiniatureFactory.sphere(root,at,size,LEATHER)
	MiniatureFactory.box(root,at+Vector3(0,size.y*0.23,-size.z*0.36),Vector3(size.x*0.86,size.y*0.36,0.038),LEATHER.lightened(0.18))
	WeaponSculpt.metal(MiniatureFactory.box(root,at+Vector3(0,0,-size.z*0.53),Vector3(0.051,0.052,0.021),BRASS))


static func band(root: Node3D,a: Vector3,b: Vector3,color: Color,width: float=0.035) -> void:
	CreatureSculpt.limb(root,a,b,width,color,1.0)


static func rivet(root: Node3D,at: Vector3,color: Color=BRASS) -> void:
	WeaponSculpt.metal(MiniatureFactory.sphere(root,at,Vector3.ONE*0.047,color))
