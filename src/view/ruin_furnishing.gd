class_name RuinFurnishing
extends RefCounted
## Geometry is scaled to the exact rule footprint and nominal terrain height.
const WOOD:=Color("73513b")
const STONE:=Color("9b9b91")
const IRON:=Color("414c53")


static func build(root: Node3D,p: TerrainPiece) -> void:
	var model:=Node3D.new()
	root.add_child(model)
	var r:=p.rect
	model.position=TableSpace.to_world(r.get_center(),0.0)
	if r.size.y>r.size.x:
		model.rotation.y=PI*0.5
	match p.kind.id:
		"ruin_timber_wall": timber(model)
		"ruin_market_counter": counter(model)
		"ruin_altar": altar(model)
		"ruin_workbench": workbench(model)
		"ruin_hearth": hearth(model)
		"ruin_archive_shelf": archive(model)
		"ruin_grave": grave(model)
	MiniatureBatch.bake(model)
	model.scale=Vector3(maxf(r.size.x,r.size.y),p.kind.height,minf(r.size.x,r.size.y))


static func box(root: Node3D,x: float,y: float,z: float,w: float,h: float,d: float,tint: Color) -> MeshInstance3D:
	return MiniatureFactory.box(root,Vector3(x,y,z),Vector3(w,h,d),tint)


static func timber(root: Node3D) -> void:
	box(root,0,0.43,0,1,0.86,0.84,Color("ada796"))
	for x: float in [-0.45,-0.15,0.18,0.45]:
		box(root,x,0.46,0,0.075,0.92,0.99,WOOD.darkened(0.14))
	for y: float in [0.10,0.46,0.79]:
		box(root,0,y,0,1,0.065,0.98,WOOD)
	for z: float in [-0.45,0.45]:
		for i in 3:
			var brace:=box(root,-0.31+i*0.31,0.62,z,0.045,0.30,0.08,WOOD.darkened(0.08))
			brace.rotation.z=0.65 if i%2==0 else -0.65
	box(root,-0.36,0.93,0,0.15,0.13,0.86,Color("938d80"))


static func counter(root: Node3D) -> void:
	box(root,0,0.38,0,0.88,0.74,0.85,WOOD.darkened(0.18))
	box(root,0,0.80,0,1,0.12,1,WOOD.lightened(0.18))
	for x: float in [-0.37,0,0.37]:
		box(root,x,0.39,-0.46,0.07,0.69,0.065,WOOD.lightened(0.12))
	for i in 3:
		box(root,-0.31+i*0.22,0.91,0.11,0.16,0.10,0.29,Color("a78e62").darkened(i*0.12))


static func altar(root: Node3D) -> void:
	box(root,0,0.10,0,1,0.20,1,STONE.darkened(0.2))
	box(root,0,0.43,0,0.76,0.60,0.72,STONE)
	box(root,0,0.78,0,1,0.16,1,STONE.lightened(0.16))
	for x: float in [-0.27,0,0.27]:
		box(root,x,0.47,-0.39,0.10,0.36,0.06,STONE.darkened(0.22))
	box(root,0,0.92,0,0.20,0.12,0.36,Color("857754"))


static func workbench(root: Node3D) -> void:
	box(root,0,0.29,0,0.82,0.58,0.81,WOOD.darkened(0.20))
	box(root,0,0.69,0,1,0.14,1,WOOD)
	for x: float in [-0.35,0.35]:
		box(root,x,0.38,0,0.12,0.73,0.90,IRON)
	for i in 3:
		MiniatureFactory.cylinder(root,Vector3(-0.28+0.23*i,0.85,0.13),0.045,0.075,0.20,Color("517972").lerp(Color("91735b"),i*0.4))
	box(root,0.26,0.82,-0.23,0.28,0.08,0.31,Color("b0a17f"))


static func hearth(root: Node3D) -> void:
	box(root,0,0.20,0,1,0.40,1,STONE.darkened(0.20))
	box(root,-0.32,0.60,0,0.32,0.80,0.86,STONE)
	box(root,0.32,0.60,0,0.32,0.80,0.86,STONE.darkened(0.08))
	box(root,0,0.50,0.25,0.35,0.40,0.36,STONE.darkened(0.40))
	for x: float in [-0.12,0.14]:
		box(root,x,0.27,-0.13,0.10,0.12,0.40,WOOD.darkened(0.4))


static func archive(root: Node3D) -> void:
	box(root,0,0.43,0.27,1,0.86,0.46,WOOD.darkened(0.28))
	for x: float in [-0.45,0.45]:
		box(root,x,0.48,0,0.10,0.96,1,WOOD)
	for shelf in 3:
		var y:=0.06+shelf*0.27
		box(root,0,y,0,1,0.065,1,WOOD.lightened(0.08))
		for i in 5:
			if (shelf+i)%4==0:
				continue
			var tint:=Color("795446").lerp(Color("596e72"),float((i+shelf)%3)*0.45)
			box(root,-0.32+i*0.16,y+0.14,-0.08,0.12,0.20,0.56,tint)
	box(root,-0.12,0.84,0.08,0.60,0.075,0.84,WOOD.darkened(0.10))


static func grave(root: Node3D) -> void:
	box(root,0,0.20,0,0.94,0.40,0.92,STONE.darkened(0.14))
	var lid:=PrismMesh.new()
	lid.size=Vector3(0.92,0.40,0.85)
	MiniatureFactory.mesh(root,lid,Vector3(0,0.60,0),STONE.lightened(0.10))
	box(root,0.04,0.81,0,0.08,0.10,0.52,STONE.darkened(0.25))
	box(root,0.04,0.81,0,0.32,0.10,0.12,STONE.darkened(0.25))
