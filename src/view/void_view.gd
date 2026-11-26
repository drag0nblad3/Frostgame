class_name VoidView
extends RefCounted
## Stylized planar void: dark mask and luminous lip, not a physical floor cutout.
static func build(board: Board) -> Node3D:
	var root := Node3D.new()
	root.name="DimensionalVoid"
	var dark := StandardMaterial3D.new()
	dark.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	dark.albedo_color=Color(0.018,0.009,0.045)
	var rim := StandardMaterial3D.new()
	rim.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	rim.albedo_color=Color(0.61,0.23,0.92)
	for region in board.void_regions:
		_box(root,region.get_center(),Vector3(region.size.x,0.025,region.size.y),0.06,dark)
		_box(root,Vector2(region.get_center().x,region.position.y),Vector3(region.size.x,0.04,0.10),0.10,rim)
		var inner_x := region.end.x if region.get_center().x<board.size.x*0.5 else region.position.x
		_box(root,Vector2(inner_x,region.get_center().y),Vector3(0.10,0.04,region.size.y),0.10,rim)
		for i in 9:
			var x := region.position.x+region.size.x*(float(i)+0.5)/9.0
			var y := region.position.y+region.size.y*(0.2+0.6*fposmod(float(i)*0.618,1.0))
			var spark := SphereMesh.new()
			spark.radius=0.035+0.02*(i%3)
			spark.height=spark.radius*2.0
			spark.radial_segments=6
			spark.rings=3
			var node := MeshInstance3D.new()
			node.mesh=spark
			node.position=TableSpace.to_world(Vector2(x,y),0.12)
			node.material_override=rim
			node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(node)
	for edge in 2:
		for i in 6:
			var label := Label3D.new()
			label.text=str(i+1)
			label.font_size=64
			label.pixel_size=0.016
			label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
			label.modulate=Color(0.85,0.69,1.0)
			label.position=TableSpace.to_world(Vector2(0.25 if edge==0 else board.size.x-0.25,mini(30,i*6)),0.7)
			root.add_child(label)
	return root


static func _box(root: Node3D,at: Vector2,size: Vector3,height: float,mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size=size
	var node := MeshInstance3D.new()
	node.mesh=mesh
	node.position=TableSpace.to_world(at,height)
	node.material_override=mat
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(node)
