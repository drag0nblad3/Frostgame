class_name BoundaryView
extends RefCounted
## Lightweight scenario barriers: solid ground strip for movement restrictions,
## translucent veil for sight restrictions. No physics bodies or animated shaders.
static func build(board: Board) -> Node3D:
	var root := Node3D.new()
	root.name="BattleBoundaries"
	for line in board.boundaries:
		var a: Vector2=line["a"]
		var b: Vector2=line["b"]
		var distance := a.distance_to(b)
		if distance<0.001:
			continue
		var blocks_move: bool=line.get("movement",false)
		var blocks_sight: bool=line.get("sight",false)
		var tint := Color(0.94,0.25,0.16) if blocks_move else Color(0.39,0.74,0.96)
		var count := maxi(1,ceili(distance/4.0))
		for i in count:
			var start := a.lerp(b,float(i)/count)
			var end := a.lerp(b,float(i+1)/count)
			var center := (start+end)*0.5
			var bottom := minf(board.ground_height_at(start),board.ground_height_at(end))
			var top := maxf(board.ground_height_at(start),board.ground_height_at(end))
			var length := start.distance_to(end)
			_bar(root,center,top+0.075,Vector3(length,0.15,0.20),end-start,tint)
			if blocks_sight:
				var height := 2.6+top-bottom
				_bar(root,center,bottom+height*0.5,Vector3(length,height,0.035),end-start,Color(tint,0.20))
	return root


static func _bar(root: Node3D,at: Vector2,y: float,size: Vector3,axis: Vector2,tint: Color) -> void:
	var shape := BoxMesh.new()
	shape.size=size
	var mesh := MeshInstance3D.new()
	mesh.mesh=shape
	mesh.position=TableSpace.to_world(at,y)
	mesh.rotation.y=-axis.angle()
	mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=tint
	if tint.a<1.0:
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override=mat
	root.add_child(mesh)
