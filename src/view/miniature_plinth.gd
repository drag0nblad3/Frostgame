class_name MiniaturePlinth
extends RefCounted
## Snow-dusted broken paving on a colored 25 mm rim. No collision or rules.
const STONE := Color("79858b")
const SNOW := Color("dce5e7")


static func create(root: Node3D,id: int) -> void:
	var top := Node3D.new()
	top.name="ScenicTop"
	root.add_child(top)
	MiniatureFactory.cylinder(top,Vector3(0,0.105,0),0.43,0.45,0.035,Color("46535a"))
	for i in 6:
		var a := TAU*i/6.0+float(posmod(id,7))*0.13
		var at := Vector3(cos(a)*0.31,0.122,sin(a)*0.31)
		var stone := MiniatureFactory.box(top,at,Vector3(0.15,0.028,0.12),STONE.lightened(0.055*float(i%3)))
		stone.rotation.y=a
		if posmod(id+i,3)!=0:
			MiniatureFactory.sphere(top,at+Vector3(0,0.015,0),Vector3(0.13,0.023,0.105),SNOW)
	var variant := posmod(id,3)
	var at := Vector3(0.23,0.135,0.21)
	if variant==0:
		var slab := MiniatureFactory.box(top,at,Vector3(0.18,0.065,0.12),STONE.darkened(0.16))
		slab.rotation.y=0.55
		MiniatureFactory.sphere(top,at+Vector3(0,0.037,0),Vector3(0.14,0.025,0.10),SNOW)
	elif variant==1:
		for i in 2:
			CreatureSculpt.limb(top,at+Vector3(i*0.055,0,0),at+Vector3(i*0.055-0.04,0.13,0.015),0.033,Color("a9c6d2"),0.02)
	else:
		CreatureSculpt.limb(top,at-Vector3(0.12,0,0),at+Vector3(0.09,0.035,0.04),0.035,Color("6e5845"),0.5)
	# The top stays inside the colored rim and clear of the health bar.
	MiniatureBatch.bake(top)
