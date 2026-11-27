class_name RealmScenery
extends RefCounted
## Abstract exterior monuments for encounters outside the normal city.
const REALMS := ["red_king_mind","red_king_bridge","red_king_ringworld","red_king_tethers"]


static func special(id: String) -> bool:
	return id in REALMS


static func build(root: Node3D,board: Board,scenario: String) -> void:
	var base := Color("473b65") if scenario!="red_king_ringworld" else Color("713e53")
	var edge := Color("9cadd0") if scenario!="red_king_ringworld" else Color("df9b7d")
	for side in 4:
		var district := Node3D.new()
		district.name="District%d"%side
		root.add_child(district)
		var length := board.size.x if side%2==0 else board.size.y
		var count := 3 if GraphicsQuality.mode()==0 else 5
		for i in count:
			var u := (i+0.5)*length/count
			var gap := 5.0+float(posmod(i*7+side*3,6))
			var p := Vector2(u,-gap) if side==0 else (Vector2(board.size.x+gap,u) if side==1 else (Vector2(u,board.size.y+gap) if side==2 else Vector2(-gap,u)))
			var at := Vector3(p.x,0,p.y)
			var seed := side*11+i*3
			match scenario:
				"red_king_mind":
					_memory(district,at,base,edge,seed)
				"red_king_bridge":
					_shard(district,at,base,edge,seed)
				_:
					_pillar(district,at,base,edge,seed)
		MiniatureBatch.bake(district)
		for child in district.get_children():
			if child is MeshInstance3D:
				child.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _memory(root: Node3D,at: Vector3,base: Color,edge: Color,seed: int) -> void:
	var h := 2.3+float(seed%5)*0.55
	for x: float in [-0.7,0.7]:
		MiniatureFactory.box(root,at+Vector3(x,h*0.5,0),Vector3(0.33,h,0.40),base)
	MiniatureFactory.box(root,at+Vector3(0,h,0),Vector3(1.80,0.22,0.48),edge.darkened(0.3))
	var shard := MiniatureFactory.box(root,at+Vector3(0,h*0.57,0.12),Vector3(0.78,1.1,0.20),edge.darkened(0.12))
	shard.rotation.z=0.30*sin(seed)


static func _shard(root: Node3D,at: Vector3,base: Color,edge: Color,seed: int) -> void:
	var h := 1.7+float(seed%6)*0.45
	var spike := MiniatureFactory.cylinder(root,at+Vector3.UP*h*0.5,0.05,0.85,h,base)
	spike.rotation.z=0.22*sin(seed)
	for i in 2:
		var small := MiniatureFactory.cylinder(root,at+Vector3((i-0.5)*1.4,0.7,0.5),0.03,0.43,1.4,edge.darkened(0.24))
		small.rotation.z=(i-0.5)*0.4


static func _pillar(root: Node3D,at: Vector3,base: Color,edge: Color,seed: int) -> void:
	var h := 3.1+float(seed%4)*0.55
	MiniatureFactory.box(root,at+Vector3.UP*0.18,Vector3(1.72,0.36,1.72),base.darkened(0.15))
	MiniatureFactory.cylinder(root,at+Vector3.UP*h*0.5,0.39,0.68,h,base)
	for y in [h*0.35,h*0.80]:
		MiniatureFactory.cylinder(root,at+Vector3.UP*y,0.70,0.70,0.10,edge.darkened(0.2))
	var crown := MiniatureFactory.box(root,at+Vector3.UP*(h+0.35),Vector3(0.72,0.72,0.72),edge)
	crown.rotation=Vector3(0.62,0.4,0.62)
