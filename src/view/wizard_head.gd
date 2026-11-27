class_name WizardHead
extends RefCounted
## Small faceted sculpted heads; silhouette and features vary independently of school.

static func sculpt(root: Node3D,skin: Color,hair: Color,index: int,apprentice: bool) -> void:
	var variant := posmod(index,4)
	var width: float = [0.30,0.34,0.31,0.29][variant]
	var length: float = [0.35,0.33,0.38,0.36][variant]
	_face_mesh(root,Vector3(0,1.32,-0.015),Vector3(width,length,0.30),skin)
	_face_mesh(root,Vector3(0,1.245,-0.045),Vector3(width*0.82,0.18,0.23),skin.darkened(0.04))
	_face_mesh(root,Vector3(0,1.41,0.045),Vector3(width*1.09,0.25,0.31),hair)
	for side: float in [-1.0,1.0]:
		var x := side*width*0.44
		_face_mesh(root,Vector3(x,1.30,0),Vector3(0.065,0.10,0.075),skin)
		_face_mesh(root,Vector3(x*0.56,1.29,-0.129),Vector3(0.10,0.10,0.076),skin.lightened(0.06))
		_face_mesh(root,Vector3(x*0.51,1.335,-0.155),Vector3(0.054,0.039,0.026),skin.darkened(0.23))
		_face_mesh(root,Vector3(x*0.51,1.335,-0.168),Vector3(0.036,0.028,0.017),Color("252526"))
		var brow := MiniatureFactory.box(root,Vector3(x*0.51,1.361,-0.157),Vector3(0.065,0.017,0.023),hair)
		brow.rotation.z=side*(0.13 if variant==1 else -0.10)
	_face_mesh(root,Vector3(0,1.29,-0.177),Vector3(0.060+0.009*variant,0.089,0.085),skin.lightened(0.07))
	MiniatureFactory.box(root,Vector3(0,1.238,-0.163),Vector3(0.084,0.013,0.022),skin.darkened(0.26))
	if not apprentice and variant in [0,2]:
		_beard(root,hair,variant==0)
	elif variant in [1,3]:
		for side: float in [-1.0,1.0]:
			var a := Vector3(side*0.14,1.39,0.045)
			var b := Vector3(side*0.17,1.25,0.065)
			CreatureSculpt.limb(root,a,b,0.065,hair,0.90)
			CreatureSculpt.limb(root,b,b+Vector3(side*0.035,-0.12,0.03),0.054,hair,0.22)
		if variant==3:
			for i in 3:
				_face_mesh(root,Vector3(-0.13+i*0.10,1.435,-0.045),Vector3(0.12,0.12,0.22),hair.lightened(0.03*i))


static func _face_mesh(root: Node3D,p: Vector3,size: Vector3,color: Color) -> void:
	var shape := SphereMesh.new()
	shape.radius=0.5
	shape.height=1.0
	var quality := MiniatureFactory.detail(root) if size.length()>0.18 else 0
	shape.radial_segments=[12,20,28][quality]
	shape.rings=[7,12,16][quality]
	MiniatureFactory.mesh(root,shape,p,color).scale=size


static func _beard(root: Node3D,hair: Color,long: bool) -> void:
	var depth := 0.26 if long else 0.13
	_face_mesh(root,Vector3(0,1.21-depth*0.30,-0.145),Vector3(0.21,depth,0.17),hair)
	for i in 5:
		var x := (i-2)*0.036
		var a := Vector3(x,1.19,-0.20)
		var b := a+Vector3(x*0.18,-depth*(0.50-absf(x)),0.018)
		CreatureSculpt.limb(root,a,b,0.022,hair.lightened(0.06*(i%2)),0.12)
	for side: float in [-1.0,1.0]:
		CreatureSculpt.limb(root,Vector3(0,1.255,-0.18),Vector3(side*0.082,1.23,-0.174),0.024,hair,0.20)
