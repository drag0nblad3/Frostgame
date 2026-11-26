class_name BoneSculpt
extends RefCounted
## Separate bones, hollow rib cage, jaw and articulated arms.
const BONE := Color("d2c8ae")
const OLD := Color("a99b7c")
const DARK := Color("303338")
const IRON := Color("626b69")
const RUST := Color("886247")


static func create(root: Node3D,f: Figure) -> void:
	var armored := f.def.id=="armoured_skeleton"
	var archer := f.def.id=="skeleton_archer"
	for side: float in [-1.0,1.0]:
		var hip := Vector3(side*0.12,0.61,0)
		var knee := Vector3(side*0.17,0.34,-0.03 if side>0 else 0.04)
		var foot := Vector3(side*0.17,0.08,-0.07)
		_bone(root,hip,knee,0.061)
		_bone(root,knee,foot,0.045)
		CreatureSculpt.limb(root,knee+Vector3(side*0.055,0,0),foot+Vector3(side*0.035,0,0),0.022,OLD,0.9)
		for i in 3:
			CreatureSculpt.limb(root,foot+Vector3((i-1)*0.035,0,0.01),foot+Vector3((i-1)*0.046,-0.025,-0.14),0.024,BONE,0.65)
		MiniatureFactory.sphere(root,hip,Vector3(0.19,0.22,0.20),BONE)
		var pivot := MiniaturePose.arm(root,side>0)
		var first := root.get_child_count()
		var shoulder := Vector3(side*0.26,1.11,0)
		var elbow := Vector3(side*0.34,0.93,0.015)
		var hand := Vector3(side*0.37,0.76,-0.09)
		_bone(root,shoulder,elbow,0.050)
		_bone(root,elbow,hand,0.035)
		CreatureSculpt.limb(root,elbow+Vector3(side*0.047,0,0),hand+Vector3(side*0.032,0,0),0.022,OLD,0.85)
		MiniatureFactory.sphere(root,hand,Vector3(0.12,0.12,0.10),BONE)
		for i in 3:
			CreatureSculpt.limb(root,hand+Vector3((i-1)*0.032,0,-0.025),hand+Vector3((i-1)*0.033,-0.065,-0.063),0.017,BONE,0.5)
		if armored:
			var plate := MiniatureFactory.sphere(root,shoulder,Vector3(0.29,0.21,0.28),IRON)
			WeaponSculpt.metal(plate)
			WeaponSculpt.metal(MiniatureFactory.box(root,elbow+Vector3(0,-0.04,-0.055),Vector3(0.14,0.18,0.05),RUST))
		MiniaturePose.attach(root,pivot,first)
	for i in 9:
		MiniatureFactory.sphere(root,Vector3(0,0.66+i*0.068,0.055),Vector3(0.105,0.077,0.11),OLD if i%2==0 else BONE)
	for i in 5:
		var y := 0.84+i*0.064
		var width := 0.18+0.045*sin(float(i)*0.65)
		for side: float in [-1.0,1.0]:
			var a := Vector3(side*0.02,y,0.05)
			var b := Vector3(side*width,y+0.02,-0.015)
			var c := Vector3(side*width*0.74,y-0.033,-0.15)
			CreatureSculpt.limb(root,a,b,0.023,BONE,0.91)
			CreatureSculpt.limb(root,b,c,0.022,BONE,0.83)
			CreatureSculpt.limb(root,c,Vector3(side*0.035,y-0.042,-0.18),0.019,BONE,0.72)
	CreatureSculpt.limb(root,Vector3(0,0.86,-0.17),Vector3(0,1.15,-0.17),0.039,OLD,0.7)
	skull(root,Vector3(0,1.36,-0.02),1.0)
	if armored:
		WeaponSculpt.metal(MiniatureFactory.sphere(root,Vector3(0,1.01,-0.16),Vector3(0.45,0.34,0.12),IRON))
		MiniatureFactory.box(root,Vector3(0,0.79,-0.20),Vector3(0.30,0.15,0.05),RUST)
		WeaponSculpt.metal(MiniatureFactory.sphere(root,Vector3(0,1.48,0.01),Vector3(0.40,0.22,0.35),IRON))
		WeaponSculpt.metal(MiniatureFactory.box(root,Vector3(0,1.40,-0.19),Vector3(0.04,0.15,0.05),RUST))
	elif archer:
		SoldierKit.decorate(root,f,Color("77705f"),Color("4d4b45"))
	MiniatureFactory.weapon(root,f)


static func _bone(root: Node3D,a: Vector3,b: Vector3,r: float) -> void:
	CreatureSculpt.limb(root,a,b,r*0.67,BONE,0.93)
	for at: Vector3 in [a,b]:
		MiniatureFactory.sphere(root,at,Vector3.ONE*r*2.05,OLD)


static func skull(root: Node3D,p: Vector3,size: float) -> void:
	MiniatureFactory.sphere(root,p,Vector3(0.34,0.34,0.30)*size,BONE)
	MiniatureFactory.sphere(root,p+Vector3(0,-0.11,-0.075)*size,Vector3(0.23,0.13,0.19)*size,OLD)
	for side: float in [-1.0,1.0]:
		MiniatureFactory.sphere(root,p+Vector3(side*0.087,0.008,-0.143)*size,Vector3(0.113,0.10,0.07)*size,DARK)
		MiniatureFactory.sphere(root,p+Vector3(side*0.114,-0.051,-0.11)*size,Vector3(0.082,0.075,0.10)*size,BONE)
		CreatureSculpt.eye(root,p+Vector3(side*0.086,0.006,-0.18)*size,Color("9dd8a1"))
	MiniatureFactory.sphere(root,p+Vector3(0,-0.057,-0.151)*size,Vector3(0.054,0.061,0.045)*size,DARK)
	MiniatureFactory.box(root,p+Vector3(0,-0.108,-0.16)*size,Vector3(0.18,0.039,0.04)*size,DARK)
	for i in 5:
		for row in 2:
			MiniatureFactory.box(root,p+Vector3((i-2)*0.033,-0.093-row*0.035,-0.181)*size,Vector3(0.027,0.032,0.033)*size,BONE)
