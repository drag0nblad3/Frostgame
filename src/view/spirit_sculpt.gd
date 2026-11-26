class_name SpiritSculpt
extends RefCounted
## Tapered swirling cloth and smoke geometry, rather than stacked spheres.
const GOLD := Color("bea16a")
const DARK := Color("202937")
const BLUE := Color("547d94")


static func wraith(root: Node3D) -> void:
	var fabric := Color("3e5265")
	_vortex(root,fabric,0.30,0.83,0.65)
	WizardTailoring.torso(root,fabric,fabric.lightened(0.16),0,false)
	ClothSculpt.hood(root,fabric.darkened(0.15))
	MiniatureFactory.sphere(root,Vector3(0,1.35,-0.13),Vector3(0.27,0.32,0.18),DARK)
	for side: float in [-1.0,1.0]:
		CreatureSculpt.eye(root,Vector3(side*0.075,1.37,-0.222),Color("9ce6ec"))
		var pivot := MiniaturePose.arm(root,side>0)
		var first := root.get_child_count()
		var shoulder := Vector3(side*0.26,1.12,0)
		var elbow := Vector3(side*0.40,0.91,-0.04)
		var hand := Vector3(side*0.48,1.04,-0.28)
		CreatureSculpt.limb(root,shoulder,elbow,0.15,fabric,1.1)
		CreatureSculpt.limb(root,elbow,hand,0.16,fabric.darkened(0.12),0.52)
		MiniatureFactory.sphere(root,hand,Vector3(0.13,0.14,0.14),Color("92aab2"))
		for i in 3:
			CreatureSculpt.limb(root,hand+Vector3((i-1)*0.04,0,-0.03),hand+Vector3((i-1)*0.055,0.08,-0.13),0.019,Color("a4bec3"),0.10)
		MiniaturePose.attach(root,pivot,first)
	ClothSculpt.cape(root,fabric.darkened(0.1),0.94,0.44)
	for i in 5:
		var x := (i-2)*0.11
		CreatureSculpt.limb(root,Vector3(x,0.48,0.19),Vector3(x*1.35,0.14+0.04*(i%2),0.42),0.05,fabric.lightened(0.12),0.01)


static func genie(root: Node3D) -> void:
	_vortex(root,BLUE.darkened(0.18),0.34,0.88,1.1)
	MiniatureFactory.sphere(root,Vector3(0,1.04,0),Vector3(0.68,0.60,0.43),BLUE)
	for side: float in [-1.0,1.0]:
		var pivot := MiniaturePose.arm(root,side>0)
		var first := root.get_child_count()
		var a := Vector3(side*0.28,1.16,0)
		var b := Vector3(side*0.48,1.00,-0.06)
		var c := Vector3(side*0.55,1.23,-0.28)
		MiniatureFactory.sphere(root,a,Vector3(0.31,0.30,0.32),BLUE.lightened(0.12))
		CreatureSculpt.limb(root,a,b,0.15,BLUE)
		CreatureSculpt.limb(root,b,c,0.12,BLUE.lightened(0.06),0.77)
		WeaponSculpt.metal(CreatureSculpt.limb(root,b.lerp(c,0.66),b.lerp(c,0.92),0.14,GOLD,1.0))
		MiniatureFactory.sphere(root,c,Vector3(0.18,0.18,0.18),BLUE.lightened(0.15))
		if side>0:
			CreatureSculpt.eye(root,c+Vector3(0,0.12,-0.06),Color("ffce86"))
		MiniaturePose.attach(root,pivot,first)
	WizardHead.sculpt(root,BLUE.lightened(0.17),DARK,4,false)
	MiniatureFactory.sphere(root,Vector3(0,1.48,0.03),Vector3(0.44,0.23,0.39),Color("d0c3a3"))
	for y: float in [1.46,1.53]:
		var wrap := MiniatureFactory.cylinder(root,Vector3(0,y,0.02),0.20,0.21,0.055,GOLD)
		wrap.rotation.z=0.15
	WeaponSculpt.metal(MiniatureFactory.sphere(root,Vector3(0,1.50,-0.19),Vector3(0.12,0.14,0.06),GOLD))
	CreatureSculpt.eye(root,Vector3(0,1.50,-0.23),Color("facd7c"))
	WeaponSculpt.metal(MiniatureFactory.cylinder(root,Vector3(0,0.80,0),0.26,0.25,0.10,GOLD)).scale.z=0.76


static func _vortex(root: Node3D,color: Color,width: float,height: float,twist: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector3]=[]
	const SEG := 16
	for j in 8:
		var t := float(j)/7.0
		var center := Vector3(sin(t*TAU*twist)*0.19*(1.0-t),0.12+t*height,cos(t*TAU*twist)*0.15*(1.0-t))
		var radius := lerpf(0.035,width,pow(t,0.78))
		for i in SEG+1:
			var angle := TAU*i/SEG+t*TAU*twist
			var r := radius*(1.0+0.12*cos(angle*5.0+t*3.0))
			pts.append(center+Vector3(cos(angle)*r,0,sin(angle)*r*0.72))
	for j in 7:
		for i in SEG:
			var a := j*(SEG+1)+i
			var b := a+SEG+1
			for k: int in [a,b,a+1,a+1,b,b+1]:
				st.add_vertex(pts[k])
	st.generate_normals()
	var node := MiniatureFactory.mesh(root,st.commit(),Vector3.ZERO,color)
	var mat: StandardMaterial3D=node.material_override
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	for i in 4:
		for j in 7:
			var k := i*4+j*(SEG+1)
			CreatureSculpt.limb(root,pts[k],pts[k+SEG+1],0.023,color.lightened(0.13),0.95)
