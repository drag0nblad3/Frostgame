class_name MiniaturePlinth
extends RefCounted
## Seeded scenic bases: all dressing stays within the original colored rim.
const STONE := Color("79858b")
const SNOW := Color("dce5e7")
const SOIL := Color("51514e")
const WOOD := Color("79614c")


static func create(root: Node3D,id: int) -> void:
	var top := Node3D.new()
	top.name="ScenicTop"
	root.add_child(top)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(id)+":scenic")
	var variant := rng.randi_range(0,5)
	var ground := [STONE.darkened(0.35),SOIL,STONE.darkened(0.22),Color("7f959f"),WOOD.darkened(0.35),SOIL.darkened(0.12)]
	MiniatureFactory.cylinder(top,Vector3(0,0.105,0),0.43,0.45,0.035,ground[variant])
	var angle := rng.randf_range(0,TAU)
	# Off-center patches rather than identical radial paving.
	var count := rng.randi_range(4,8)
	for i in count:
		var a := angle+rng.randf_range(0,TAU)
		var radius := rng.randf_range(0.19,0.32)
		var at := Vector3(cos(a)*radius,0.135,sin(a)*radius)
		var w := rng.randf_range(0.07,0.16)
		var d := rng.randf_range(0.045,0.105)
		match variant:
			0,2:
				var slab := MiniatureFactory.box(top,at,Vector3(w,0.025,d),STONE.lightened(rng.randf_range(-0.12,0.19)))
				slab.rotation.y=angle+rng.randf_range(-0.35,0.35) if variant==0 else a
			1,5:
				var chip := MiniatureFactory.sphere(top,at,Vector3(w,0.035,d),STONE.darkened(rng.randf_range(0.0,0.3)))
				chip.rotation.y=a
			3:
				var ice := MiniatureFactory.box(top,at,Vector3(w,0.02,d),Color("b4ced8").darkened(rng.randf_range(0.0,0.2)))
				ice.rotation.y=a
			4:
				var plank := MiniatureFactory.box(top,at,Vector3(w,0.025,d*0.55),WOOD.lightened(rng.randf_range(0.0,0.16)))
				plank.rotation.y=angle
		if rng.randf()< (0.82 if variant==3 else 0.38):
			MiniatureFactory.sphere(top,at+Vector3.UP*0.018,Vector3(w*0.85,0.024,d),SNOW.darkened(rng.randf_range(0.0,0.12)))
	# One small asymmetric focal detail, kept away from the figure's feet.
	var edge := Vector3(cos(angle)*0.27,0.145,sin(angle)*0.27)
	var tangent := Vector3(-sin(angle),0,cos(angle))
	match variant:
		0:
			var broken := MiniatureFactory.box(top,edge,Vector3(0.15,0.065,0.10),STONE.lightened(0.15))
			broken.rotation.y=angle
		1:
			for i in 3:
				var offset := tangent*(float(i)-1.0)*0.045
				CreatureSculpt.limb(top,edge+offset,edge+offset+Vector3.UP*rng.randf_range(0.04,0.10)+tangent*0.025,0.012,Color("8b8064"),0.12)
		2:
			CreatureSculpt.limb(top,edge-tangent*0.065,edge+tangent*0.065+Vector3.UP*0.025,0.022,Color("bcb4a1"),0.75)
		3:
			for i in 2:
				var offset := tangent*(float(i)-0.5)*0.055
				CreatureSculpt.limb(top,edge+offset,edge+offset+Vector3.UP*rng.randf_range(0.06,0.13),0.025,Color("a9c6d2"),0.02)
		4:
			CreatureSculpt.limb(top,edge-tangent*0.08,edge+tangent*0.08+Vector3.UP*0.025,0.026,WOOD,0.55)
		5:
			var disc := MiniatureFactory.cylinder(top,edge,0.045,0.045,0.025,Color("b49a61"))
			disc.rotation.z=0.15
			MiniatureFactory.sphere(top,edge+tangent*0.07,Vector3(0.05,0.035,0.06),Color("8d7754"))
	MiniatureBatch.bake(top)
