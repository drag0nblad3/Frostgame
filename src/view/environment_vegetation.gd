class_name EnvironmentVegetation
extends RefCounted
## Sparse winter plants. Ground cover is a low silhouette; trees are scenic only.
const BARK := Color("66594c")
const NEEDLES := Color("475f58")
const SNOW := Color("bdcbd2")


static func ground_cover(root: Node3D,at: Vector3,seed: int) -> void:
	# Nearly flush, deliberately does not imply an extra terrain obstacle.
	for i in 4:
		var a := seed*0.44+i*1.47
		var b := at+Vector3(cos(a)*0.18,0.014,sin(a)*0.18)
		CreatureSculpt.limb(root,at,b,0.017,Color("918573").lightened(i*0.035),0.15)


static func shrub(root: Node3D,at: Vector3,seed: int) -> void:
	for i in 5:
		var a := seed*0.35+i*TAU/5.0
		var end := at+Vector3(cos(a)*0.50,0.52+0.11*(i%3),sin(a)*0.50)
		var elbow := at.lerp(end,0.62)+Vector3.UP*0.10
		CreatureSculpt.limb(root,at,elbow,0.055,BARK,0.68)
		CreatureSculpt.limb(root,elbow,end,0.035,BARK.lightened(0.14),0.08)
		CreatureSculpt.limb(root,elbow,elbow+Vector3(-sin(a)*0.16,0.20,cos(a)*0.16),0.023,BARK,0.08)
	MiniatureFactory.sphere(root,at+Vector3.UP*0.07,Vector3(0.7,0.14,0.60),SNOW)


static func tree(root: Node3D,at: Vector3,seed: int,evergreen: bool) -> void:
	var h := 2.3+0.17*float(posmod(seed,5))
	if evergreen:
		CreatureSculpt.limb(root,at,at+Vector3.UP*h,0.16,BARK,0.48)
		for i in 3:
			var r := 0.78-i*0.19
			var y := 0.72+i*0.54
			MiniatureFactory.cylinder(root,at+Vector3.UP*y,0.08,r,1.05,NEEDLES.lightened(i*0.07))
			MiniatureFactory.cylinder(root,at+Vector3.UP*(y+0.24),0.025,r*0.60,0.65,SNOW.darkened(0.06*i))
	else:
		var fork := at+Vector3(0.10,h*0.57,-0.08)
		var tip := at+Vector3(-0.18,h,0.10)
		CreatureSculpt.limb(root,at,fork,0.20,BARK,0.55)
		CreatureSculpt.limb(root,fork,tip,0.11,BARK.lightened(0.10),0.15)
		for i in 5:
			var a := seed*0.17+i*2.40
			var base := at.lerp(tip,0.40+0.08*i)
			var b := base+Vector3(cos(a)*0.65,0.42,sin(a)*0.65)
			var c := b+Vector3(cos(a)*0.37,0.40,sin(a)*0.37)
			CreatureSculpt.limb(root,base,b,0.095,BARK,0.55)
			CreatureSculpt.limb(root,b,c,0.050,BARK.lightened(0.12),0.08)
			CreatureSculpt.limb(root,b,b+Vector3(-sin(a)*0.28,0.36,cos(a)*0.28),0.035,BARK,0.05)
		for i in 4:
			var a := i*TAU/4.0
			CreatureSculpt.limb(root,at+Vector3.UP*0.25,at+Vector3(cos(a)*0.48,0.04,sin(a)*0.48),0.10,BARK,0.04)
